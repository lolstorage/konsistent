--[[
    Konsistent v1.4
    lolstorage king blud
--]]

local Konsistent = {}

-- Constant Types
local LUA_TNIL = 0
local LUA_TBOOLEAN = 1
local LUA_TNUMBER = 2
local LUA_TSTRING = 3
local LUA_TVECTOR = 4

local OpCodes = {
    [0]   = { name = "NOP",             format = "none" },
    [1]   = { name = "BREAK",           format = "none" },
    [2]   = { name = "LOADNIL",         format = "A" },
    [3]   = { name = "LOADBOOL",        format = "ABC" },
    [4]   = { name = "LOADN",           format = "AsD" },
    [5]   = { name = "LOADK",           format = "AD" },
    [6]   = { name = "MOVE",            format = "AB" },
    [7]   = { name = "GETGLOBAL",       format = "AC", aux = true },
    [8]   = { name = "SETGLOBAL",       format = "AC", aux = true },
    [9]   = { name = "GETUPVAL",        format = "AB" },
    [10]  = { name = "SETUPVAL",        format = "AB" },
    [11]  = { name = "CLOSEUPVALS",     format = "A" },
    [12]  = { name = "GETIMPORT",       format = "AD", aux = true },
    [13]  = { name = "GETTABLE",        format = "ABC" },
    [14]  = { name = "SETTABLE",        format = "ABC" },
    [15]  = { name = "GETTABLEKS",      format = "ABC", aux = true },
    [16]  = { name = "SETTABLEKS",      format = "ABC", aux = true },
    [17]  = { name = "GETTABLEN",       format = "ABC" },
    [18]  = { name = "SETTABLEN",       format = "ABC" },
    [19]  = { name = "NEWCLOSURE",      format = "AD" },
    [20]  = { name = "NAMECALL",        format = "ABC", aux = true },
    [21]  = { name = "CALL",            format = "ABC" },
    [22]  = { name = "RETURN",          format = "AB" },
    [23]  = { name = "JUMP",            format = "D" },
    [24]  = { name = "JUMPIF",          format = "AD" },
    [25]  = { name = "JUMPIFNOT",       format = "AD" },
    [26]  = { name = "JUMPIFEQ",        format = "AD", aux = true },
    [27]  = { name = "JUMPIFNEQ",       format = "AD", aux = true },
    [28]  = { name = "JUMPIFLT",        format = "AD", aux = true },
    [29]  = { name = "JUMPIFLE",        format = "AD", aux = true },
    [30]  = { name = "JUMPIFGT",        format = "AD", aux = true },
    [31]  = { name = "JUMPIFGE",        format = "AD", aux = true },
    [32]  = { name = "JUMPIFEQK",       format = "AD", aux = true },
    [33]  = { name = "JUMPIFNEQK",      format = "AD", aux = true },
    [34]  = { name = "JUMPIFLTK",       format = "AD", aux = true },
    [35]  = { name = "JUMPIFLEK",       format = "AD", aux = true },
    [36]  = { name = "JUMPIFGTK",       format = "AD", aux = true },
    [37]  = { name = "JUMPIFGEK",       format = "AD", aux = true },
    [38]  = { name = "ADD",             format = "ABC" },
    [39]  = { name = "SUB",             format = "ABC" },
    [40]  = { name = "MUL",             format = "ABC" },
    [41]  = { name = "DIV",             format = "ABC" },
    [42]  = { name = "MOD",             format = "ABC" },
    [43]  = { name = "POW",             format = "ABC" },
    [44]  = { name = "ADDK",            format = "ABC" },
    [45]  = { name = "SUBK",            format = "ABC" },
    [46]  = { name = "MULK",            format = "ABC" },
    [47]  = { name = "DIVK",            format = "ABC" },
    [48]  = { name = "MODK",            format = "ABC" },
    [49]  = { name = "POWK",            format = "ABC" },
    [50]  = { name = "AND",             format = "ABC" },
    [51]  = { name = "OR",              format = "ABC" },
    [52]  = { name = "ANDK",            format = "ABC" },
    [53]  = { name = "ORK",             format = "ABC" },
    [54]  = { name = "CONCAT",          format = "ABC" },
    [55]  = { name = "NOT",             format = "AB" },
    [56]  = { name = "MINUS",           format = "AB" },
    [57]  = { name = "LENGTH",          format = "AB" },
    [58]  = { name = "NEWTABLE",        format = "AB", aux = true },
    [59]  = { name = "DUPTABLE",        format = "AD" },
    [60]  = { name = "SETLIST",         format = "ABC", aux = true },
    [61]  = { name = "FORNPREP",        format = "AsD" },
    [62]  = { name = "FORNLOOP",        format = "AsD" },
    [63]  = { name = "FORGPREP",        format = "AsD" },
    [64]  = { name = "FORGLOOP",        format = "ABC", aux = true },
    [65]  = { name = "FORGPREP_INEXT",  format = "AsD" },
    [66]  = { name = "FASTCALL1",       format = "ABC" },
    [67]  = { name = "FASTCALL2",       format = "ABC", aux = true },
    [68]  = { name = "FASTCALL2K",      format = "ABC", aux = true },
    [69]  = { name = "FORGPREP_NEXT",   format = "AsD" },
    [70]  = { name = "DEP_NATIVECALL",  format = "none" },
    [71]  = { name = "GETVARARGS",      format = "AB" },
    [72]  = { name = "DUPCLOSURE",      format = "AD" },
    [73]  = { name = "PREPVARARGS",     format = "A" },
    [74]  = { name = "LOADKX",          format = "A", aux = true },
    [75]  = { name = "JUMPIFEQKS",      format = "AD", aux = true },
    [76]  = { name = "JUMPIFNEQKS",     format = "AD", aux = true },
    [77]  = { name = "IDIV",            format = "ABC" },
    [78]  = { name = "IDIVK",           format = "ABC" },
}

local StreamReader = {}
StreamReader.__index = StreamReader

function StreamReader.new(buffer: string)
    return setmetatable({
        Buffer = buffer,
        Offset = 1,
        Length = #buffer
    }, StreamReader)
end

function StreamReader:ReadByte(): number
    if self.Offset > self.Length then return 0 end
    local byte = string.byte(self.Buffer, self.Offset)
    self.Offset = self.Offset + 1
    return byte
end

function StreamReader:ReadVarInt(): number
    local result = 0
    local shift = 0
    while true do
        local byte = self:ReadByte()
        result = bit32.bor(result, bit32.lshift(bit32.band(byte, 0x7F), shift))
        if bit32.band(byte, 0x80) == 0 then break end
        shift = shift + 7
    end
    return result
end

function StreamReader:ReadInt32(): number
    local b1, b2, b3, b4 = self:ReadByte(), self:ReadByte(), self:ReadByte(), self:ReadByte()
    return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

function StreamReader:ReadDouble(): number
    local bytes = {}
    for i = 1, 8 do bytes[i] = self:ReadByte() end
    local sign = bit32.band(bytes[8], 0x80) ~= 0 and -1 or 1
    local exponent = bit32.lshift(bit32.band(bytes[8], 0x7F), 4) + bit32.rshift(bit32.band(bytes[7], 0xF0), 4)
    local mantissa = bit32.band(bytes[7], 0x0F)
    for i = 6, 1, -1 do
        mantissa = mantissa * 256 + bytes[i]
    end
    if exponent == 2047 then
        return 0
    elseif exponent == 0 then
        return sign * math.ldexp(mantissa, -1074)
    else
        return sign * math.ldexp(mantissa + 4503599627370496, exponent - 1023 - 52)
    end
end

function StreamReader:ReadString(len: number): string
    if len <= 0 then return "" end
    local str = string.sub(self.Buffer, self.Offset, self.Offset + len - 1)
    self.Offset = self.Offset + len
    return str
end

local function DecodeInstruction(ins: number)
    local op = bit32.band(ins, 0xFF)
    local a  = bit32.band(bit32.rshift(ins, 8), 0xFF)
    local b  = bit32.band(bit32.rshift(ins, 16), 0xFF)
    local c  = bit32.band(bit32.rshift(ins, 24), 0xFF)
    local d  = bit32.band(bit32.rshift(ins, 16), 0xFFFF)
    
    local signedD = d
    if signedD >= 0x8000 then
        signedD = signedD - 0x10000
    end

    return {
        Opcode = op,
        A = a,
        B = b,
        C = c,
        D = d,
        SignedD = signedD
    }
end

local function GetInstructionSize(op: number): number
    local opData = OpCodes[op]
    if opData and opData.aux then
        return 2
    end
    return 1
end

local function IsJumpOrBranch(op: number): boolean
    return (op == 23) or (op >= 24 and op <= 37) or (op == 75) or (op == 76)
end

function Konsistent.BuildFullCFG(proto)
    local instructions = proto.Instructions
    local instructionCount = proto.InstructionCount
    
    local leaders = {[1] = true}
    local pc = 1
    
    while pc <= instructionCount do
        local rawIns = instructions[pc]
        if not rawIns then break end
        local op = bit32.band(rawIns, 0xFF)
        local insSize = GetInstructionSize(op)
        
        if IsJumpOrBranch(op) then
            local ins = DecodeInstruction(rawIns)
            local targetPC = pc + ins.SignedD + 1
            if targetPC >= 1 and targetPC <= instructionCount then
                leaders[targetPC] = true
            end
            local fallthroughPC = pc + insSize
            if fallthroughPC <= instructionCount then
                leaders[fallthroughPC] = true
            end
        elseif op == 22 then -- RETURN
            local fallthroughPC = pc + insSize
            if fallthroughPC <= instructionCount then
                leaders[fallthroughPC] = true
            end
        elseif op >= 61 and op <= 65 then
            local ins = DecodeInstruction(rawIns)
            local targetPC = pc + ins.SignedD + 1
            if targetPC >= 1 and targetPC <= instructionCount then
                leaders[targetPC] = true
            end
            local fallthroughPC = pc + insSize
            if fallthroughPC <= instructionCount then
                leaders[fallthroughPC] = true
            end
        end
        pc = pc + insSize
    end
    
    local sortedLeaders = {}
    for leaderPC, _ in pairs(leaders) do
        table.insert(sortedLeaders, leaderPC)
    end
    table.sort(sortedLeaders)
    
    local blocks = {}
    local pcToBlock = {}
    
    for i = 1, #sortedLeaders do
        local startPC = sortedLeaders[i]
        local endPC = sortedLeaders[i + 1] and (sortedLeaders[i + 1] - 1) or instructionCount
        
        local block = {
            ID = i,
            StartPC = startPC,
            EndPC = endPC,
            Instructions = {},
            Successors = {},
            Predecessors = {}
        }
        
        local currentPC = startPC
        while currentPC <= endPC and currentPC <= instructionCount do
            local raw = instructions[currentPC]
            if not raw then break end
            table.insert(block.Instructions, {
                PC = currentPC,
                Raw = raw
            })
            pcToBlock[currentPC] = block
            local op = bit32.band(raw, 0xFF)
            currentPC = currentPC + GetInstructionSize(op)
        end
        blocks[i] = block
    end
    
    for _, block in ipairs(blocks) do
        local lastPC = block.EndPC
        local rawIns = instructions[lastPC]
        if rawIns then
            local op = bit32.band(rawIns, 0xFF)
            local insSize = GetInstructionSize(op)
            local isTerminator = false
            
            if op == 23 or (op >= 61 and op <= 65) or IsJumpOrBranch(op) then
                local ins = DecodeInstruction(rawIns)
                local targetPC = lastPC + ins.SignedD + 1
                local targetBlock = pcToBlock[targetPC]
                if targetBlock then
                    table.insert(block.Successors, targetBlock)
                    table.insert(targetBlock.Predecessors, block)
                end
                local fallthroughPC = lastPC + insSize
                local fallthroughBlock = pcToBlock[fallthroughPC]
                if fallthroughBlock then
                    table.insert(block.Successors, fallthroughBlock)
                    table.insert(fallthroughBlock.Predecessors, block)
                end
                isTerminator = true
            elseif op == 22 then
                isTerminator = true
            end
            
            if not isTerminator then
                local fallthroughPC = lastPC + insSize
                local fallthroughBlock = pcToBlock[fallthroughPC]
                if fallthroughBlock then
                    table.insert(block.Successors, fallthroughBlock)
                    table.insert(fallthroughBlock.Predecessors, block)
                end
            end
        end
    end
    
    return blocks
end

function Konsistent.Deserialize(bytecode: string)
    local stream = StreamReader.new(bytecode)
    local version = stream:ReadByte()
    if version == 0 then
        error("sum FUCKING ERROR. Invalid bytecode or compilation failure.")
    end
    
    local typesVersion = 0
    if version >= 4 then
        typesVersion = stream:ReadByte()
    end

    -- Skip modern Luau type tables introduced in Version 6+
    if version >= 6 then
        local typesCount = stream:ReadVarInt()
        for i = 1, typesCount do
            stream:ReadByte()
        end
    end
    
    local stringCount = stream:ReadVarInt()
    local stringTable = {}
    for i = 1, stringCount do
        local len = stream:ReadVarInt()
        stringTable[i] = stream:ReadString(len)
    end
    
    local protoCount = stream:ReadVarInt()
    local protos = {}
    
    for i = 1, protoCount do
        local proto = {
            MaxStackSize = stream:ReadByte(),
            NumParameters = stream:ReadByte(),
            NumUpvalues = stream:ReadByte(),
            IsVararg = stream:ReadByte() == 1,
        }
        
        if version >= 4 then
            proto.Flags = stream:ReadByte()
            local typesLen = stream:ReadVarInt()
            if typesLen > 0 then
                proto.TypeInfo = stream:ReadString(typesLen)
            end
        end
        
        proto.InstructionCount = stream:ReadVarInt()
        proto.Instructions = {}
        for j = 1, proto.InstructionCount do
            proto.Instructions[j] = stream:ReadInt32()
        end
        
        proto.ConstantCount = stream:ReadVarInt()
        proto.Constants = {}
        for j = 1, proto.ConstantCount do
            local constType = stream:ReadByte()
            local constant = nil
            
            if constType == LUA_TNIL then
                constant = { Type = "Nil", Value = nil }
            elseif constType == LUA_TBOOLEAN then
                constant = { Type = "Boolean", Value = (stream:ReadByte() == 1) }
            elseif constType == LUA_TNUMBER then
                constant = { Type = "Number", Value = stream:ReadDouble() }
            elseif constType == LUA_TSTRING then
                local stringID = stream:ReadVarInt()
                constant = { Type = "String", Value = stringTable[stringID] }
            elseif constType == LUA_TVECTOR then
                for v = 1, 16 do stream:ReadByte() end
                constant = { Type = "Vector", Value = "[Vector]" }
            end
            proto.Constants[j - 1] = constant
        end
        
        proto.ChildProtoCount = stream:ReadVarInt()
        proto.ChildProtos = {}
        for j = 1, proto.ChildProtoCount do
            proto.ChildProtos[j] = stream:ReadVarInt()
        end
        
        proto.LineDefined = stream:ReadVarInt()
        local debugNameID = stream:ReadVarInt()
        proto.DebugName = stringTable[debugNameID] or "anonymous"
        
        if stream:ReadByte() == 1 then
            proto.LineGapLog2 = stream:ReadByte()
            local intervals = bit32.rshift(proto.InstructionCount - 1, proto.LineGapLog2) + 1
            proto.LineInfo = {}
            local lastLine = 0
            for j = 1, proto.InstructionCount do
                lastLine = lastLine + stream:ReadByte()
                proto.LineInfo[j] = lastLine
            end
            proto.AbsLineInfo = {}
            for j = 1, intervals do
                proto.AbsLineInfo[j] = stream:ReadInt32()
            end
        end
        
        if stream:ReadByte() == 1 then
            proto.LocalVariables = {}
            local localCount = stream:ReadVarInt()
            for j = 1, localCount do
                proto.LocalVariables[j] = {
                    Name = stringTable[stream:ReadVarInt()],
                    StartPC = stream:ReadVarInt(),
                    EndPC = stream:ReadVarInt(),
                    Reg = stream:ReadByte()
                }
            end
            proto.UpvalueNames = {}
            local upvalueCount = stream:ReadVarInt()
            for j = 1, upvalueCount do
                proto.UpvalueNames[j] = stringTable[stream:ReadVarInt()]
            end
        end
        
        proto.CFGBlocks = Konsistent.BuildFullCFG(proto)
        protos[i - 1] = proto
    end
    
    local mainProtoId = stream:ReadVarInt()
    return {
        BytecodeVersion = version,
        TypesVersion = typesVersion,
        StringTable = stringTable,
        Protos = protos,
        MainProto = protos[mainProtoId]
    }
end

local function decompile(scriptPath)
    assert(getscriptbytecode, "[Konsistent] getscriptbytecode required!")
    local success, bytecode = pcall(getscriptbytecode, scriptPath)
    if not success then
        return "-- [Konsistent Error]: Failed to grab bytecode:\n--" .. tostring(bytecode)
    end
    
    local successParse, result = pcall(Konsistent.Deserialize, bytecode)
    if not successParse then
        return "-- sum error or sum: Deserialization failed:\n--" .. tostring(result)
    end
    
    local output = "-- konsistent - Version " .. tostring(result.BytecodeVersion) .. "]\n\n"
    
    for id, proto in pairs(result.Protos) do
        output = output .. string.format("function %s() -- Proto %s (Line: %s)\n", proto.DebugName, tostring(id), tostring(proto.LineDefined))
        output = output .. string.format("    -- sum stack: %d | Params: %d | CFG Blocks: %d\n\n", proto.MaxStackSize, proto.NumParameters, #proto.CFGBlocks)
        
        for _, block in ipairs(proto.CFGBlocks) do
            output = output .. string.format("    [some CFG Block %d] StartPC: %d, EndPC: %d\n", block.ID, block.StartPC, block.EndPC)
        end
        output = output .. "\n"
        
        local pc = 1
        while pc <= proto.InstructionCount do
            local rawIns = proto.Instructions[pc]
            if not rawIns then break end
            local ins = DecodeInstruction(rawIns)
            local opData = OpCodes[ins.Opcode]
            local opName = opData and opData.name or ("UNKNOWN_OP_" .. tostring(ins.Opcode))
            local line = proto.LineInfo and proto.LineInfo[pc] or "?"
            
            local instStr = string.format("    [%3d][Line %-3s]  %-14s R%d", pc, tostring(line), opName, ins.A)
            
            if opData then
                if opData.format == "AB" then
                    instStr = instStr .. string.format(", R%d", ins.B)
                elseif opData.format == "ABC" then
                    instStr = instStr .. string.format(", R%d, R%d", ins.B, ins.C)
                elseif opData.format == "AD" then
                    instStr = instStr .. string.format(", %d", ins.D)
                elseif opData.format == "AsD" then
                    instStr = instStr .. string.format(", %d", ins.SignedD)
                end
            end
            
            if opName == "LOADK" then
                local const = proto.Constants[ins.D]
                instStr = instStr .. string.format(" -- Constant: %s", const and tostring(const.Value) or "nil")
            elseif opName == "GETGLOBAL" or opName == "SETGLOBAL" or opName == "LOADKX" then
                pc = pc + 1
                local aux = proto.Instructions[pc]
                local const = proto.Constants[aux]
                instStr = instStr .. string.format(" -- Aux Global: %s", const and tostring(const.Value) or tostring(aux))
            elseif opName == "GETTABLEKS" or opName == "SETTABLEKS" or opName == "NAMECALL" then
                pc = pc + 1
                local aux = proto.Instructions[pc]
                local const = proto.Constants[aux]
                instStr = instStr .. string.format(", R%d, K(%d) -- Member: %s", ins.B, aux, const and tostring(const.Value) or "nil")
            end
            
            output = output .. instStr .. "\n"
            pc = pc + GetInstructionSize(ins.Opcode)
        end
        output = output .. "end\n\n"
    end
    
    return output
end

getgenv().decompile = decompile
getgenv().disassemble = decompile
print("konsistent loaded for fucking up shit.")
