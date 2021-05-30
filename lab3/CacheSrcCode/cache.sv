module cache #(
    parameter  LINE_ADDR_LEN = 3, // line内地址长度，决定了每个line具有2^3个word
    parameter  SET_ADDR_LEN  = 3, // 组地址长度，决定了一共有2^3=8组
    parameter  TAG_ADDR_LEN  = 6, // tag长度
    parameter  WAY_CNT       = 3  // 组相连度，决定了每组中有多少路line，这里是直接映射型cache，因此该参数没用到
)(
    input  clk, rst,
    output miss,               // 对CPU发出的miss信号
    input  [31:0] addr,        // 读写请求地址
    input  rd_req,             // 读请求信号
    output reg [31:0] rd_data, // 读出的数据，一次读一个word
    input  wr_req,             // 写请求信号
    input  [31:0] wr_data      // 要写入的数据，一次写一个word
);

localparam MEM_ADDR_LEN    = TAG_ADDR_LEN + SET_ADDR_LEN ; // 计算主存地址长度 MEM_ADDR_LEN，主存大小=2^MEM_ADDR_LEN个line
localparam UNUSED_ADDR_LEN = 32 - TAG_ADDR_LEN - SET_ADDR_LEN - LINE_ADDR_LEN - 2 ;       // 计算未使用的地址的长度

localparam LINE_SIZE       = 1 << LINE_ADDR_LEN  ;         // 计算 line 中 word 的数量，即 2^LINE_ADDR_LEN 个word 每 line
localparam SET_SIZE        = 1 << SET_ADDR_LEN   ;         // 计算一共有多少组，即 2^SET_ADDR_LEN 个组

reg [            31:0] cache_mem    [SET_SIZE][WAY_CNT][LINE_SIZE]; // SET_SIZE个组，WAY_CNT个line，每个line有LINE_SIZE个word
reg [TAG_ADDR_LEN-1:0] cache_tags   [SET_SIZE][WAY_CNT];            // SET_SIZE*WAY_CNT个TAG
reg                    valid        [SET_SIZE][WAY_CNT];            // SET_SIZE*WAY_CNT个valid(有效位)
reg                    dirty        [SET_SIZE][WAY_CNT];            // SET_SIZE*WAY_CNT个dirty(脏位)
reg [     WAY_CNT-1:0] way_addr;        // 记录hit的组地址
reg [     WAY_CNT-1:0] way_hit;         // 记录组是否hit

wire [              2-1:0]   word_addr;         // 将输入地址addr拆分成这5个部分
wire [  LINE_ADDR_LEN-1:0]   line_addr;
wire [   SET_ADDR_LEN-1:0]    set_addr;
wire [   TAG_ADDR_LEN-1:0]    tag_addr;
wire [UNUSED_ADDR_LEN-1:0] unused_addr;
wire [        WAY_CNT-1:0]  index_addr;         // 记录换出入的组内地址，采用不同策略改变

enum  {IDLE, SWAP_OUT, SWAP_IN, SWAP_IN_OK} cache_stat;    // cache 状态机的状态定义
                                                           // IDLE代表就绪，SWAP_OUT代表正在换出，SWAP_IN代表正在换入，SWAP_IN_OK代表换入后进行一周期的写入cache操作。

reg  [   SET_ADDR_LEN-1:0] mem_rd_set_addr = 0;
reg  [   TAG_ADDR_LEN-1:0] mem_rd_tag_addr = 0;
reg  [        WAY_CNT-1:0] mem_rd_index_addr = 0;     // 换入换出的mem组内地址
wire [   MEM_ADDR_LEN-1:0] mem_rd_addr = {mem_rd_tag_addr, mem_rd_set_addr};
reg  [   MEM_ADDR_LEN-1:0] mem_wr_addr = 0;

reg  [31:0] mem_wr_line [LINE_SIZE];
wire [31:0] mem_rd_line [LINE_SIZE];

wire mem_gnt;      // 主存响应读写的握手信号

assign {unused_addr, tag_addr, set_addr, line_addr, word_addr} = addr;  // 拆分 32bit ADDR

reg cache_hit = 1'b0;

always @ (*) begin    // 判断输入的address 是否在 cache 中某一路命中并记录信息
    for (interger i = 0; i < WAY_CNT; i = i+1 ) begin
        if (valid[set_addr][i] && cache_tags[set_addr][i]==tag_addr) begin
            way_hit[i] <= 1;
            way_addr <= i;
        end
        else begin
            way_hit[i] <= 0;
        end
    end
end

always @(*) begin               // 根据是否命中返回cache_hit信息
    if (way_hit) cache_hit <= 1;
    else cache_hit <= 0;
end


// implement FIFO
reg [WAY_CNT-1:0] FIFOQueue [SET_SIZE][WAY_CNT];    //FIFO队列寄存器
reg [WAY_CNT-1:0] FIFO_addr;            //FIFO产生的way_addr，可以用于cache
reg [WAY_CNT-1:0] Front [SET_SIZE];     //队头信息
reg [WAY_CNT-1:0] Rear  [SET_SIZE];     //队尾信息
reg flag;

initial begin
    for (integer i = 0;i < SET_SIZE;i++) begin
        Front[i] = 0;
        Rear[i] = 0;
    end
end

always @ (*) begin
    if (cache_stat == IDLE && !cache_hit && (rd_req | wr_req)) begin // 需要读或者写
        flag = 0;
        for (integer i = 0;i < WAY_CNT;i++) begin
            if (!flag && !valid[set_addr][i]) begin     // 这一路有空的地址，可以直接使用
                flag = 1;
                FIFO_addr = i;
            end
        end
        if (!flag) begin                       // 所有位都有效，那么修改队头队尾，分配一个队头位置
            FIFO_addr = FIFOQueue[set_addr][Front[set_addr]];   // 等于队头地址（相当于把队头移除）
            if (Front[set_addr] != Rear[set_addr])              // 队头不是队尾，那么说明队列里是有数据的，更新队头位置
                Front[set_addr] = (Front[set_addr] + 1) % WAY_CNT;
        end
    end
    else if (cache_stat == SWAP_IN_OK) begin // 将换入的地址加入队列，更新队头队尾
        FIFOQueue[mem_rd_set_addr][Rear[mem_rd_set_addr]] = mem_rd_index_addr;
        Rear[mem_rd_set_addr] = (Rear[mem_rd_set_addr] + 1) % WAY_CNT;
    end
end

// implement LRU
reg [31:0] Usage [SET_SIZE][WAY_CNT];   // 记录使用次数
reg [WAY_CNT-1:0] LRU_addr;             // LRU产生的换入地址
integer max;

initial begin
    for (integer i = 0;i < SET_SIZE;i++) begin
        for (integer j = 0;j < WAY_CNT;j++) begin
            Usage[i][j] = 0;
        end
    end
end

always @ (posedge clk or posedge rst) begin
    if (rst) begin
        for (integer i = 0;i < SET_SIZE;i++) begin
            for (integer j = 0;j < WAY_CNT;j++) 
                Usage[i][j] = 0;
        end
    end
    else begin
        for (integer i = 0;i < SET_SIZE;i++) begin  // 开始时，对每一个数的未使用次数+1
            for (integer j = 0;j < WAY_CNT;j++) 
                Usage[i][j] = Usage[i][j] + 1;
        end
        max = 0;
        for (integer i = 0;i < WAY_CNT;i++) begin
            if (max < Usage[set_addr][i]) begin
                max = Usage[set_addr][i];      // 找到最久不用的地址将它清除
                LRU_addr = i;
            end
        end
        if (cache_stat == IDLE && cache_hit) // 命中了以后应当将该处设置成0
            Usage[set_addr][way_addr] = 0;
        else if (cache_stat == SWAP_IN_OK) // 换入的地址对应的使用应当是最少的
            Usage[mem_rd_set_addr][mem_rd_index_addr] = 0;
    end
end

assign index_addr = LRU_addr;

always @ (posedge clk or posedge rst) begin     // ?? cache ???
    if(rst) begin                      // 初始化，如果rst，则将valid和dirty置为0
        cache_stat <= IDLE;
        for(integer i = 0; i < SET_SIZE; i++) begin
            for (integer j = 0; j < WAY_CNT; j++) begin
                dirty[i][j] = 1'b0;
                valid[i][j] = 1'b0;
            end
        end
        for(integer k = 0; k < LINE_SIZE; k++)
            mem_wr_line[k] <= 0;
        mem_wr_addr <= 0;
        {mem_rd_tag_addr, mem_rd_set_addr,mem_rd_index_addr} <= 0;
        rd_data <= 0;
    end else begin
        case(cache_stat)
        IDLE:       begin                       // 准备就绪
                        if(cache_hit) begin
                            if(rd_req) begin    // 如果cache命中，并且是读请求，
                                rd_data <= cache_mem[set_addr][way_addr][line_addr];   //则直接从cache中取出要读的数据
                            end else if(wr_req) begin // 如果cache命中，并且是写请求，
                                cache_mem[set_addr][way_addr][line_addr] <= wr_data;   // 则直接向cache中写入数据
                                dirty[set_addr][way_addr] <= 1'b1;                     // 写数据的同时置脏位
                            end 
                        end else begin
                            if(wr_req | rd_req) begin   // 如果 cache 未命中，并且有读写请求，则需要进行换入
                                if(valid[set_addr][index_addr] & dirty[set_addr][index_addr]) begin    // 如果 要换入的cache line 本来有效，且脏，则需要先将它换出
                                    cache_stat  <= SWAP_OUT;
                                    mem_wr_addr <= {cache_tags[set_addr][index_addr], set_addr};
                                    mem_wr_line <= cache_mem[set_addr][index_addr];
                                end else begin                                   // 反之，不需要换出，直接换入
                                    cache_stat  <= SWAP_IN;
                                end
                                {mem_rd_tag_addr, mem_rd_set_addr,mem_rd_index_addr} <= {tag_addr, set_addr,index_addr};
                            end
                        end
                    end
        SWAP_OUT:   begin
                        if(mem_gnt) begin           // 如果主存握手信号有效，说明换出成功，跳到下一状态
                            cache_stat <= SWAP_IN;
                        end
                    end
        SWAP_IN:    begin
                        if(mem_gnt) begin           // 如果主存握手信号有效，说明换入成功，跳到下一状态
                            cache_stat <= SWAP_IN_OK;
                        end
                    end
        SWAP_IN_OK: begin           // 上一个周期换入成功，这周期将主存读出的line写入cache，并更新tag，置高valid，置低dirty
                        for(integer i=0; i<LINE_SIZE; i++)  cache_mem[mem_rd_set_addr][mem_rd_index_addr][i] <= mem_rd_line[i];
                        cache_tags[mem_rd_set_addr][mem_rd_index_addr] <= mem_rd_tag_addr;
                        valid     [mem_rd_set_addr][mem_rd_index_addr] <= 1'b1;
                        dirty     [mem_rd_set_addr][mem_rd_index_addr] <= 1'b0;
                        cache_stat <= IDLE;        // 回到就绪状态
                    end
        endcase
    end
end

wire mem_rd_req = (cache_stat == SWAP_IN );
wire mem_wr_req = (cache_stat == SWAP_OUT);
wire [   MEM_ADDR_LEN-1 :0] mem_addr = mem_rd_req ? mem_rd_addr : ( mem_wr_req ? mem_wr_addr : 0);

assign miss = (rd_req | wr_req) & ~(cache_hit && cache_stat==IDLE) ;     // 当 有读写请求时，如果cache不处于就绪(IDLE)状态，或者未命中，则miss=1

main_mem #(     // 主存，每次读写以line 为单位
    .LINE_ADDR_LEN  ( LINE_ADDR_LEN          ),
    .ADDR_LEN       ( MEM_ADDR_LEN           )
) main_mem_instance (
    .clk            ( clk                    ),
    .rst            ( rst                    ),
    .gnt            ( mem_gnt                ),
    .addr           ( mem_addr               ),
    .rd_req         ( mem_rd_req             ),
    .rd_line        ( mem_rd_line            ),
    .wr_req         ( mem_wr_req             ),
    .wr_line        ( mem_wr_line            )
);


endmodule





