# PNS (Poodle Navigation System)

PNS (Poodle Navigation System) is an add-on for Shergood Aviation helicopters with an AFCS (autopilot).

PNS allows a pilot to enter a set of instructions for the AFCS based on the regions the aircraft passes through.

# Example

This set of instructions plots a course to navigate the aircraft from SLNH to SLHA:

```
pns new
pns add x x 90 Allalinhorn
pns add x x  0 Turvile
pns add x x 90 Nautilus - Ysthyalm
pns add x x  0 Marmedunc
pns add x x 90 Blake Sea - Swab
pns add x x  0 Blake Sea - China
pns add 0 x  x Santa Catalina
```

# Commands

## `pns`
Activate/deactivate the system. When active, the system will issue commands to the AFCS upon reaching the regions specified in the instructions.

## `pns new`
Clear any stored instructions and create a new route.

## `pns add <IAS> <ALT> <HDG> <region>`
Add an instruction. When the aircraft enters the designated region, the specified IAS, ALT, and HDG holds will be set in the AFCS.

An `x` for the IAS, ALT or HDG means the aircraft will maintain its current value for this setting.

Setting `0` for IAS will not just set the IAS to 0, but will also activate autohover mode.

## `pns ins <line> <IAS> <ALT> <HDG> <region>`
Insert an instruction before the specified line.

## `pns del <line>`
Delete the specified line from the instructions.

## `pns list`
Print the current set of stored instructions with their line numbers.

## `pns rev`
Reverse the current instructions to create a return route.

## `pns save <name>`
Save the current route with the alias <name>.

## `pns load <name>`
Load a stored route with the alias <name>.

## `pns erase <name>`
Delete a stored route with the alias <name>.

## `pns stored`
Print a list of the stored routes.
