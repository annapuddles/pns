// PNS (Poodle Navigation System) v0.11.0
//
// PNS is an add-on for Shergood Aviation helicopters with an AFCS (autopilot).
//
// PNS allows a pilot to enter a set of instructions for the AFCS system based
// on the regions the aircraft passes through.
//
// For example:
//
// pns new
// pns add x x 90 Allalinhorn
// pns add x x  0 Turvile
// pns add x x 90 Nautilus - Ysthyalm
// pns add x x  0 Marmedunc
// pns add x x 90 Blake Sea - Swab
// pns add x x  0 Blake Sea - China
// pns add 0 x  x Santa Catalina
//
// This set of instructions navigates the aircraft from SLNH to SLHA.
//
// Commands:
//
// pns <on|off>
//   Activate/deactivate the system.
//
// pns new
//   Clear any stored instructions and create a new route.
//
// pns add <ias> <alt> <hdg> <region>
//   Add an instruction. When the aircraft enters the designated region, the
//   specified IAS, ALT, and HDG holds will be set in the AFCS.
//
//   An x for the IAS, ALT or HDG means the aircraft will maintain its current
//   value for this setting.
//
//   Setting 0 for IAS will also activate autohover.
//
//   Setting 0 for ALT will also lower the gear.
//
// pns ins <line> <ias> <alt> <hdg> <region>
//   Insert an instruction before the specified line.
//
// pns del <line>
//   Delete the specified line from the instructions.
//
// pns list
//   List the current set of stored instructions with their line numbers.
//
// pns print
//   Print the current route in the .pns notecard format.
//
// pns rev
//   Reverse the current instructions to create a return route.
//
// pns save <name>
//   Save the current route with the alias <name>.
//
// pns load <name>
//   Load a stored route with the alias <name>.
//
// pns erase <name>
//   Delete a stored route with the alias <name>.
//
// pns routes
//   Print a list of the stored routes.
//
// pns strict <on|off>
//   Enable or disable strict mode. In strict mode, if the aircraft enters
//   a region that is not listed in the current route, it will enter autohover
//   mode.

// The prefix for stored route keys in the linkset data.
string stored_route_prefix = "pns:storedRoute:";

// The current route instructions.
list route;

// Whether the system is active.
integer active;

// Whether to autohover if entering a region not in the route.
integer strict;

// The avatar sitting in the pilot seat.
key pilot;

// The avatar sitting in the copilot seat.
key copilot;

// Used for reading a route from a .pns notecard.
string notecard;
key notecard_query;
integer notecard_line;

// Send a command to the AFCS.
afcs(string command)
{
    llMessageLinked(LINK_ROOT, 185, command, NULL_KEY);
}

// Adjust the AFCS based on the instructions for the current region.
adjust()
{
    if (!active)
    {
        return;
    }

    string region = llToUpper(llGetRegionName());

    integer index = llListFindStrided(route, [region], 0, -1, 4);

    if (index == -1)
    {
        if (strict)
        {
            afcs("hvr");
            announce(region + " not found in route.");
        }
        
        return;
    }

    integer ias = llList2Integer(route, index + 1);
    integer alt = llList2Integer(route, index + 2);
    integer hdg = llList2Integer(route, index + 3);

    announce("Entered " + region + ", IAS: " + pns2str(ias) + ", ALT: " + pns2str(alt) + ", HDG: " + pns2str(hdg)); 

    // Activate autohover if IAS is set to 0.
    if (ias == 0)
    {
        afcs("hvr");
    }
    else if (ias > 0)
    {
        afcs("ias " + (string) ias);
    }

    if (alt >= 0)
    {
        // Lower the gear if ALT is set to 0.
        if (alt == 0)
        {
            llMessageLinked(LINK_ROOT, 268, "0", NULL_KEY);
        }

        afcs("alt " + (string) alt);
    }

    if (hdg >= 0)
    {
        afcs("hdg " + (string) hdg);
    }

    // Pop the completed instruction, or clear the route if it is the last.
    if (index + 4 >= llGetListLength(route))
    {
        route = [];
    }
    else
    {
        route = llList2List(route, index + 4, -1);
    }    
}

// Convert user-entered string in add command to internal value.
integer str2pns(string value)
{
    if (value == "x")
    {
        return -1;
    }
    else
    {
        return (integer) value;
    }
}

// Convert an internal value to a string displayed to the user.
string pns2str(integer value)
{
    if (value == -1)
    {
        return "x";
    }
    else
    {
        return (string) value;
    }
}

// Send a message to both pilot and copilot
announce(string s)
{
    s = "[PNS] " + s;
    if (pilot)
    {
        llRegionSayTo(pilot, 0, s);
    }
    if (copilot)
    {
        llRegionSayTo(copilot, 0, s);
    }
}

// Left pad a number with spaces
string pad(integer v)
{
    string s = pns2str(v);
    integer n;
    for (n = llStringLength(s); n < 3; ++n)
    {
        s = " " + s;
    }
    return s;
}

default
{
    state_entry()
    {
        llOwnerSay("[PNS] Installed. Free Memory: " + (string) llGetFreeMemory());
        llListen(0, "", "", "");
    }

    listen(integer channel, string name, key id, string message)
    {
        if (!(id == pilot || id == copilot))
        {
            return;
        }

        list tokens = llParseString2List(message, [" "], []);

        if (llToLower(llList2String(tokens, 0)) == "pns")
        {
            string command = llToLower(llList2String(tokens, 1));

            if (command == "")
            {
                if (!active)
                {
                    active = TRUE;
                    announce("Activated");
                }

                adjust();
            }
            else if (command == "on")
            {
                active = TRUE;
                announce("Activated.");
                adjust();
            }
            else if (command == "off")
            {
                active = FALSE;
                announce("Deactivated.");
            }
            else if (command == "add")
            {
                integer ias = str2pns(llList2String(tokens, 2));
                integer alt = str2pns(llList2String(tokens, 3));
                integer hdg = str2pns(llList2String(tokens, 4));

                string region = llToUpper(llDumpList2String(llList2List(tokens, 5, -1), " "));

                route += [region, ias, alt, hdg];
                adjust();

                announce("Added " + region + "  IAS " + pns2str(ias) + "  ALT " + pns2str(alt) + "  HDG " + pns2str(hdg));
            }
            else if (command == "list")
            {
                string s = "Route:";
                integer n = llGetListLength(route);
                
                if (n == 0)
                {
                    announce("Route is empty.");
                    return;
                }
                
                integer i;
                for (i = 0; i < n; i += 4)
                {
                    string region = llList2String(route, i);
                    integer ias = llList2Integer(route, i + 1);
                    integer alt = llList2Integer(route, i + 2);
                    integer hdg = llList2Integer(route, i + 3);

                    s += "\n" + (string) (i / 4) + ": " + region + " - IAS " + pns2str(ias) + " - ALT " + pns2str(alt) + " - HDG " + pns2str(hdg);
                }
                announce(s);
            }
            else if (command == "print")
            {
                string s = "Copy into a notecard:\n#IAS ALT HDG REGION";
                integer n = llGetListLength(route);
                integer i;
                for (i = 0; i < n; i += 4)
                {
                    string region = llList2String(route, i);
                    integer ias = llList2Integer(route, i + 1);
                    integer alt = llList2Integer(route, i + 2);
                    integer hdg = llList2Integer(route, i + 3);

                    s += "\n" + pad(ias) + " " + pad(alt) + " " + pad(hdg) + " " + region;
                }
                announce(s);
            }
            else if (command == "new")
            {
                route = [];
                announce("Route cleared.");
            }
            else if (command == "rev")
            {
                list new_route;

                integer n = llGetListLength(route);
                integer i;
                for (i = n - 4; i >= 0; i -= 4)
                {
                    string region = llList2String(route, i);

                    integer ias;
                    integer alt;
                    integer hdg;

                    // The last instruction of the new route takes the values from the last
                    // instruction of the old route.
                    if (i < 4)
                    {
                        ias = llList2Integer(route, n - 3);
                        alt = llList2Integer(route, n - 2);
                        hdg = llList2Integer(route, n - 1);
                    }
                    // Other instructions take the values from the preceding instruction in
                    // the old route, with the heading flipped.
                    else
                    {
                        ias = llList2Integer(route, i - 3);
                        alt = llList2Integer(route, i - 2);
                        hdg = (llList2Integer(route, i - 1) + 180) % 360;
                    }

                    new_route += [region, ias, alt, hdg];
                }

                route = new_route;

                adjust();

                announce("Route reversed.");
            }
            else if (command == "del")
            {
                integer line = (integer) llList2String(tokens, 2);
                if (line == 0)
                {
                    route = llList2List(route, 4, -1);
                }
                else
                {
                    route = llList2List(route, 0, line * 4) + llList2List(route, (line + 1) * 4, -1);
                }
                adjust();
                announce("Deleted line " + (string) line);
            }
            else if (command == "ins")
            {
                integer line = (integer) llList2String(tokens, 2);
                integer ias = str2pns(llList2String(tokens, 3));
                integer alt = str2pns(llList2String(tokens, 4));
                integer hdg = str2pns(llList2String(tokens, 5));
                string region = llToUpper(llDumpList2String(llList2List(tokens, 6, -1), " "));

                if (line == 0)
                {
                    route = [region, ias, alt, hdg] + route;
                }
                else
                {
                    route = llList2List(route, 0, line * 4) + [region, ias, alt, hdg] + llList2List(route, (line + 1) * 4, -1);
                }

                adjust();

                announce("Added " + region + "  IAS " + pns2str(ias) + "  ALT " + pns2str(alt) + "  HDG " + pns2str(hdg) + " on line " + (string) line);
            }
            else if (command == "routes")
            {
                string text = "Stored routes:";
                list keys = llLinksetDataFindKeys(stored_route_prefix, 0, 0);
                integer n = llGetListLength(keys);
                integer i;
                for (i = 0; i < n; ++i)
                {
                    text += "\n" + llGetSubString(llList2String(keys, i), llStringLength(stored_route_prefix), -1);
                }                    
                announce(text);
            }
            else if (command == "save")
            {
                string name = llList2String(tokens, 2);
                llLinksetDataWrite(stored_route_prefix + name, llList2Json(JSON_ARRAY, route));
                announce("Saved current route as " + name);
            }
            else if (command == "load")
            {
                string name = llList2String(tokens, 2);
                route = llJson2List(llLinksetDataRead(stored_route_prefix + name));
                adjust();
                announce("Loaded stored route " + name);
            }
            else if (command == "erase")
            {
                string name = llList2String(tokens, 2);
                llLinksetDataDelete(stored_route_prefix + name);
                announce("Deleted stored route " + name);
            }
            else if (command == "strict")
            {
                string subcommand = llList2String(tokens, 2);
                if (subcommand == "on")
                {
                    strict = TRUE;
                    announce("Strict mode enabled.");
                }
                else if (subcommand == "off")
                {
                    strict = FALSE;
                    announce("Strict mode disabled.");
                }
            }
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_REGION)
        {
            adjust();
        }
        if (change & CHANGED_INVENTORY)
        {
            integer n = llGetInventoryNumber(INVENTORY_NOTECARD);
            for (n; n >= 0; --n)
            {
                notecard = llGetInventoryName(INVENTORY_NOTECARD, n);
                if (llGetSubString(notecard, -4, -1) == ".pns")
                {
                    route = [];
                    notecard_query = llGetNotecardLine(notecard, notecard_line = 0);
                    return;
                }
            }
        }
    }

    dataserver(key query_id, string data)
    {
        if (query_id != notecard_query)
        {
            return;
        }

        while (data != NAK && data != EOF)
        {
            if (llGetSubString(data, 0, 0) != "#")
            {
                list tokens = llParseString2List(data, [" "], []);

                if (llGetListLength(tokens) > 3)
                {
                    integer ias = str2pns(llList2String(tokens, 0));
                    integer alt = str2pns(llList2String(tokens, 1));
                    integer hdg = str2pns(llList2String(tokens, 2));
                    string region = llToUpper(llDumpList2String(llList2List(tokens, 3, -1), " "));
                    route += [region, ias, alt, hdg];
                }
            }

            data = llGetNotecardLineSync(notecard, ++notecard_line);
        }

        if (data == NAK)
        {
            notecard_query = llGetNotecardLine(notecard, notecard_line);
        }

        if (data == EOF)
        {
            announce("Loaded route from notecard " + notecard);
            adjust();
            llRemoveInventory(notecard);
        }
    }

    link_message(integer sender, integer num, string str, key id)
    {
        if (num == 126)
        {
            pilot = id;
            if (id) {
                announce("Registered " + llGetUsername(pilot) + " as pilot.");
            }
        }
        else if (num == 145)
        {
            copilot = id;
            if (id) {
                announce("Registered " + llGetUsername(copilot) + " as copilot.");
            }
        }
    }
}
