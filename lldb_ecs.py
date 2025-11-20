import lldb

from lldb.plugins.parsed_cmd import ParsedCommand

val = lldb.SBValue

ci = lldb.debugger.GetCommandInterpreter()

def cmd(s):
    ci.HandleCommand(s, lldb.SBCommandReturnObject())

def summary_String(val: lldb.SBValue, dont_touch):
    thread: lldb.SBThread = val.GetThread()
    process: lldb.SBProcess = thread.GetProcess()
    ptr: lldb.SBValue = val.GetChildMemberWithName("ptr")
    len: lldb.SBValue = val.GetChildMemberWithName("len")
    content: lldb.SBValue = ptr.deref
    print(content.addr.GetOffset())
    err = lldb.SBError()
    try:
        mem = process.ReadMemory(ptr.unsigned, len.unsigned, err)
    except Exception as e:
        return '{invalid}'
    if not err.Success():
        print("error: ", err.description)

    return f'"{mem.decode()}"'

cmd("type summary add -F lldb_ecs.summary_String iro::utf8::String")

def printArray(debugger, command, exe_ctx, result, internal_dict):
    frame: lldb.SBFrame = exe_ctx.GetFrame()
    array: lldb.SBValue = frame.EvaluateExpression(command)
    arr: val = array.GetChildMemberWithName("arr")
    header: val = frame.EvaluateExpression(f"(iro::ArrayHeader*){arr.value} - 1")
    len = header.GetChildMemberWithName("len").value
    ci.HandleCommand(f"parray {len} (({arr.type}){arr.value})", result)

cmd("command script add -f lldb_ecs.printArray parr")

def runLake(debugger, command, exe_ctx, result, internal_dict):
    ci = debugger.GetCommandInterpreter()
    ci.HandleCommand(f"shell lake {command}", result)
    return

cmd("command script add -f lldb_ecs.runLake lake")
