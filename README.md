<p align="center">
<img src="PNS.png">
</p>

# PNS (Poodle Navigation System)

PNS (Poodle Navigation System) is an add-on for Shergood Aviation helicopters with an AFCS (autopilot).

PNS allows a pilot to enter a set of instructions for the AFCS based on the regions the aircraft passes through. This helps to further reduce pilot workload in addition to the AFCS itself.

> **WARNING**
> 
> PNS is **not** a fully autonomous system. It is the pilot's responsibility to consider sim crossings, ban lines, obstacles other aircraft and missing sims when entering a route.

You can get PNS on the Second Life Marketplace [here](https://marketplace.secondlife.com/p/PNS-Poodle-Navigation-System-for-Shergood-Aviation-helicopters-with-AFCS/26975982).

# Example

This set of instructions plots a course to navigate the aircraft from SLNH to SLHA:

```
pns new
pns add x x 90 Allalinhorn
pns add x x 0 Turvile
pns add x x 90 Nautilus - Ysthyalm
pns add x x 0 Marmedunc
pns add x x 90 Blake Sea - Swab
pns add x x 0 Blake Sea - China
pns add 0 x x Santa Catalina
```

![Example route](Example%20route.png)

# Commands

## `pns <on|off>`
Activate/deactivate the system. When active, the system will issue commands to the AFCS upon reaching the regions specified in the instructions.

## `pns new`
Clear any stored instructions and create a new route.

## `pns add <IAS> <ALT> <HDG> <region>`
Add an instruction. When the aircraft enters the designated region, the specified IAS, ALT, and HDG holds will be set in the AFCS.

An `x` for the IAS, ALT or HDG means the aircraft will maintain its current value for this setting.

Setting `0` for IAS will also activate autohover mode.

Setting `0` for ALT will also lower the gear.

## `pns ins <line> <IAS> <ALT> <HDG> <region>`
Insert an instruction before the specified line.

## `pns del <line>`
Delete the specified line from the instructions.

## `pns list`
Print the current set of stored instructions with their line numbers.

## `pns print`
Print the current set of stored instructions in the .pns notecard format.

## `pns rev`
Reverse the current instructions to create a return route.

## `pns save <name>`
Save the current route with the alias `name`.

## `pns load <name>`
Load a stored route with the alias `name`.

## `pns erase <name>`
Delete a stored route with the alias `name`.

## `pns routes`
Print a list of the stored routes.

## `pns strict <on|off>`
Enable or disable strict mode. In strict mode, if the aircraft enters a region that is not listed in the current route, it will enter autohover mode.

# Route notecards

Routes can be stored in and loaded from a notecard. Below is an example of a route notecard:

```
#IAS ALT HDG REGION
   x   x  90 Allalinhorn
   x   x   0 Turvile
   x   x  90 Nautilus - Ysthyalm
   x   x   0 Marmedunc
   x   x  90 Blake Sea - Swab
   x   x   0 Blake Sea - China
   0   x   x Santa Catalina
```

Lines starting with `#` are ignored as comments. Extra whitespace is also ignored.

The name of the notecard must end with a `.pns` extension. Drop the notecard into the aircraft, and PNS will load the route from it, and then delete it.

The current route can be saved to a notecard by executing the `pns print` command and copying the output into a notecard.
