# LLDB python script for custom printing of types, as well as a command for
# calling lake w/o leaving the debugger.

import lldb

ci = lldb.debugger.GetCommandInterpreter()

def cmd(s):
    ci.HandleCommand(s, lldb.SBCommandReturnObject())

# TODO(sushi) iro should have its own lldb_iro.py file or something.
def summary_String(val: lldb.SBValue, dont_touch):
    thread: lldb.SBThread = val.GetThread()
    process: lldb.SBProcess = thread.GetProcess()
    ptr: lldb.SBValue = val.GetChildMemberWithName("ptr")
    len: lldb.SBValue = val.GetChildMemberWithName("len")
    err = lldb.SBError()
    try:
        mem = process.ReadMemory(ptr.GetValueAsAddress(), len.unsigned, err)
    except Exception as e:
        return '{invalid}'
    
    if not err.Success():
        print(err)

    if mem is None:
        return '{invalid}'

    return f'"{mem.decode()}"'

cmd("type summary add -F lldb_ecs.summary_String iro::utf8::String")

# TODO(sushi) this needs to print lake's output as it runs. Very annoying 
#             that it doesn't atm.
def runLake(debugger, command, exe_ctx, result, internal_dict):
    ci = debugger.GetCommandInterpreter()
    ci.HandleCommand(f"shell ./bin/lake {command}", result)
    return

cmd("command script add -f lldb_ecs.runLake lake")

def procHandle(
        dbg: lldb.SBDebugger, 
        cmd, 
        exectx: lldb.SBExecutionContext, 
        result, 
        internal_dict):
    exectx.GetThread().StepOver()
    frame: lldb.SBFrame = exectx.GetFrame()
    p: lldb.SBValue = frame.FindVariable("p")
    handle: lldb.SBValue = p.GetChildMemberWithName("handle")
    
    exectx.GetTarget().WatchAddress(
        handle.addr.GetOffset(), 8, False, True, lldb.SBError())

    return

cmd("command script add -f lldb_ecs.procHandle wproc")

