module ZNB20Module

## Import packages
import VISA
import Base: cd, cp, readdir, pwd, mkdir, rm

## Import our modules
importall PainterQB                 # All the stuff in InstrumentDefs, etc.
include(joinpath(Pkg.dir("PainterQB"),"src/Metaprogramming.jl"))

export ZNB20

export AutoSweepTime
export DisplayUpdate
export SweepTime
export Window

export cd
export cp
export hidetrace
export lstrace
export mkdir
export mktrace
export pwd
export readdir
export rm
export rmtrace
export showtrace

znbool(a) = (Bool(a) ? "ON" : "OFF")

type ZNB20 <: InstrumentVISA
    vi::(VISA.ViSession)
    writeTerminator::ASCIIString
    model::AbstractString

    ZNB20(x) = begin
        ins = new()
        ins.vi = x
        ins.writeTerminator = "\n"
        ins.model = "ZNB20"
        VISA.viSetAttribute(ins.vi, VISA.VI_ATTR_TERMCHAR_EN, UInt64(1))
        ins
    end

    ZNB20() = new()
end

responseDictionary = Dict(
    :TriggerSlope   => Dict("POS"  => :RisingTrigger,
                            "NEG"  => :FallingTrigger),

    :TriggerSource  => Dict("INT"  => :InternalTrigger,
                            "EXT"  => :ExternalTrigger,
                            "MAN"  => :ManualTrigger,
                            "MULT" => :MultipleTrigger)
)

generate_handlers(ZNB20, responseDictionary)

"Configure or inspect. Does the instrument choose the minimum sweep time?"
abstract AutoSweepTime <: InstrumentProperty

"Configure or inspect. Display updates during measurement."
abstract DisplayUpdate <: InstrumentProperty

"Configure or inspect. Adjust time it takes to complete a sweep (all partial measurements)."
abstract SweepTime <: InstrumentProperty

"`InstrumentProperty`: Window."
abstract Window <: InstrumentProperty

### Configure and inspect

"""
[SENSE#:SWEEP:TIME:AUTO](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/4e1073e7fde645a8.htm)

Determines whether or not the instrument chooses the minimum sweep time,
including all partial measurements. Channel `ch` defaults to 1.
"""
function configure(ins::ZNB20, ::Type{AutoSweepTime}, b::Bool, ch::Int=1)
    write(ins, "SENSe"*string(ch)*":SWEep:TIME:AUTO "*znbool(b))
end

"""
[SYSTEM:DISPLAY:UPDATE](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/d36e114067.htm)

Switches display update on / off.
"""
function configure(ins::ZNB20, ::Type{DisplayUpdate}, b::Bool)
    write(ins, "SYSTem:DISPlay:UPDate "*znbool(b))
end

"""
[SENSE#:SWEEP:POINTS](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/68b77d9828354b78.htm)

Define measurement points per sweep. Channel `ch` defaults to 1.
"""
function configure(ins::ZNB20, ::Type{NumPoints}, n::Int, ch::Int=1)
    write(ins, "SENSe"*string(ch)*":SWEep:POINts "*string(n))
end

"""
[SENSE#:SWEEP:TIME](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/8227ae4383e449fe.htm)

Define the time to complete a sweep, including all partial measurements.
Channel `ch` defaults to 1.
"""
function configure(ins::ZNB20, ::Type{SweepTime}, time::Real, ch::Int=1)
    write(ins, "SENSe"*string(ch)*":SWEep:TIME "*string(time))
end

"""
[DISPLAY:WINDOW#:STATE](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/065c895d5a2c4230.htm)

Turn a window on or off.
"""
function configure(ins::ZNB20, ::Type{Window}, b::Bool, win::Int)
    write(ins,"DISPlay:WINDow"*string(win)*":STATe "*znbool(b))
end

"""
[SENSE#:SWEEP:TIME:AUTO](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/4e1073e7fde645a8.htm)

Does the instrument choose the minimum sweep time,
including all partial measurements? Channel `ch` defaults to 1.
"""
function inspect(ins::ZNB20, ::Type{AutoSweepTime}, ch::Int=1)
    Bool(parse(ask(ins, "SENSe"*string(ch)*":SWEep:TIME:AUTO?")))
end

"""
[SYSTEM:DISPLAY:UPDATE](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/d36e114067.htm)

Is the display updating?
"""
function inspect(ins::ZNB20, ::Type{DisplayUpdate})
    Bool(parse(ask(ins, "SYSTem:DISPlay:UPDate?")))
end

"""
[SENSE#:SWEEP:POINTS](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/68b77d9828354b78.htm)

How many measurement points per sweep? Channel `ch` defaults to 1.
"""
function inspect(ins::ZNB20, ::Type{NumPoints}, ch::Int=1)
    parse(ask(ins, "SENSe"*string(ch)*":SWEep:POINts?"))
end

"""
[SENSE#:SWEEP:TIME](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/8227ae4383e449fe.htm)

Define the time to complete a sweep, including all partial measurements.
Channel `ch` defaults to 1.
"""
function inspect(ins::ZNB20, ::Type{SweepTime}, ch::Int=1)
    parse(ask(ins, "SENSe"*string(ch)*":SWEep:TIME?"))
end

"""
Determines if a window exists, by window number. See `lswindow`.
"""
function inspect(ins::ZNB20, ::Type{Window}, win::Int)
    nums = lswindows(ins)[1]
    findfirst(nums,win) != 0
end

"""
Determines if a window exists, by window name. See `lswindow`.
"""
function inspect(ins::ZNB20, ::Type{Window}, wname::AbstractString)
    names = lswindows(ins)[2]
    findfirst(names,wname) != 0
end

## Other commands

"""
[MMEMory:CDIRectory](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/d36e87010.htm)

Change directories. Pass "~" for default.
"""
function cd(ins::ZNB20, dir::AbstractString)
    if dir == "~"
        write(ins, "MMEMory:CDIRectory DEFault")
    else
        write(ins, "MMEMory:CDIRectory "*quoted(dir))
    end
end

"""
[MMEMory:COPY](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/d36e87048.htm)

Copy a file.
"""
function cp(ins::ZNB20, src::AbstractString, dest::AbstractString)
    write(ins, "MMEMory:COPY "*quoted(src)*","*quoted(dest))
end

"""
[DISPLAY:WINDOW#:TRACE#:DELETE](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/35e75331f5ce4fce.htm)

Releases the assignment of window trace `wtrace` to window `win`.
"""
function hidetrace(ins::ZNB20, win::Int, wtrace::Int)
    write(ins, "DISPlay:WINDow"*string(win)*":TRACe"*string(wtrace)*":DELETE")
end

"""
[CALCULATE#:PARAMETER:CATALOG?](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/2ce049f1af684d21.htm)

Report the traces assigned to a given channel.
"""
function lstrace(ins::ZNB20, ch::Int)
    res = ask(ins, "CALCulate"*string(ch)*":PARameter:CATALOG?")
end

"""
[DISPLAY:CATALOG?](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/abdd1db5dc0c48ee.htm)

Report the windows and their names in a tuple: (`arrNums::Array{Int64,1}`,
    `arrNames::Array{SubString{ASCIIString},1})`).
"""
function lswindows(ins::ZNB20)
    wins = unquoted(ask(ins, "DISPlay:CATalog?"))
    arr = split(wins,",")
    arrNums = arr[1:2:end]
    arrNames = arr[2:2:end]
    arrNums = [parse(x)::Int for x in arrNums]

    (arrNums, arrNames)
end

"""
[MMEMory:MDIRectory](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/d36e89416.htm)

Make a directory.
"""
function mkdir(ins::ZNB20, dir::AbstractString)
    write(ins, "MMEMory:MDIRectory "*quoted(dir))
end

"""
[CALCulate#:PARameter:SDEFine](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/e75d49e2a14541c5.htm)

Create a new trace with `name` and measurement `parameter` on channel `ch`.
"""
function mktrace(ins::ZNB20, name::AbstractString, parameter, ch::Int)
    cmd = "CALCulate"*ch
    cmd = cmd*":PARameter:SDEFine "*quoted(name)*","*quoted(parameter)
    write(ins, cmd)
end

"""
[MMEMory:CDIRectory?](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/d36e87010.htm)

Print the working directory.
"""
function pwd(ins::ZNB20)
    unquoted(ask(ins, "MMEMory:CDIRectory?"))
end

"""
[MMEMory:CATalog?](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/7f7650b75a604b3d.htm)

Read the directory contents.
"""
function readdir(ins::ZNB20, dir::AbstractString="")
    cmd = "MMEMory:CATalog?"
    if dir != ""
        cmd = cmd*" "*quoted(dir)
    end
    ask(ins, cmd)
end

"""
[MMEMory:DELete](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/d36e87202.htm)

Remove a file.
"""
function rm(ins::ZNB20, file::AbstractString)
    write(ins, "MMEMory:DELete "*quoted(dir))
end


"""
[CALCULATE#:PARAMETER:DELETE](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/0763f74d0a2d4d61.htm)

Remove trace with name `name` from channel `ch`.
"""
function rmtrace(ins::ZNB20, name::AbstractString, ch::Int)
    write(ins, "CALCulate"*string(ch)*":PARameter:DELete "*quoted(name))
end

"""
[CALCulate#:PARameter:DELete:CALL](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/8d937272d97244fb.htm)

Deletes all traces in the given channel.
"""
function rmtrace(ins::ZNB20, ch::Int)
    write(ins, "CALCulate"*string(ch)*":PARameter:DELete:CALL")
end

"""
[CALCulate:PARameter:DELete:ALL](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/d36e69977.htm)

Deletes all traces in all channels.
"""
function rmtrace(ins::ZNB20)
    write(ins, "CALCulate:PARameter:DELete:ALL")
end

"""
[DISPLAY:WINDOW#:TRACE#:FEED](https://www.rohde-schwarz.com/webhelp/znb_znbt_webhelp_en_5/Content/58dad852e7db48a0.htm)

Show a trace named `name` in window `win::Int` as
window trace number `wtrace::Int`.
"""
function showtrace(ins::ZNB20, name::AbstractString, win::Int, wtrace::Int)
    write(ins, "DISPlay:WINDow"*string(win)*
        ":TRACe"*string(wtrace)*":FEED "*quoted(name))
end

end