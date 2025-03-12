// PNS (Poodle Navigation System) for Shergood Aviation helicopters with AFCS
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
// pns
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
//   Setting 0 for IAS will not just set the IAS to 0, but will also activate
//   autohover mode.
//
// pns ins <line> <ias> <alt> <hdg> <region>
//   Insert an instruction before the specified line.
//
// pns del <line>
//   Delete the specified line from the instructions.
//
// pns list
//   Print the current set of stored instructions with their line numbers.
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
// pns stored
//   Print a list of the stored routes.

// The prefix for stored route keys in the linkset data.
string stored_route_prefix = "pns:storedRoute:";

// The current route instructions.
list route;

// Whether the system is active.
integer active;

// The avatar sitting in the pilot seat.
key pilot;

// The avatar sitting in the copilot seat.
key copilot;

// Used for reading a route from a .pns notecard.
string notecard;
key notecard_query;
integer notecard_line;

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
        return;
    }

    integer ias = llList2Integer(route, index + 1);
    integer alt = llList2Integer(route, index + 2);
    integer hdg = llList2Integer(route, index + 3);

    announce("Entered " + region + ", IAS: " + gps2str(ias) + ", ALT: " + gps2str(alt) + ", HDG: " + gps2str(hdg)); 

    if (ias == 0)
    {
        llMessageLinked(LINK_ROOT, 185, "hvr", NULL_KEY);
    }
    else if (ias > 0)
    {
        llMessageLinked(LINK_ROOT, 185, "ias " + (string) ias, NULL_KEY);
    }
    if (alt >= 0)
    {
        llMessageLinked(LINK_ROOT, 185, "alt " + (string) alt, NULL_KEY);
    }
    if (hdg >= 0)
    {
        llMessageLinked(LINK_ROOT, 185, "hdg " + (string) hdg, NULL_KEY);
    }
    
    route = llList2List(route, index + 4, -1);
}

// Convert user-entered string in add command to internal value.
integer str2gps(string value)
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
string gps2str(integer value)
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

// Reverse the current route
reverse_route()
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
}

// Print the current route
list_route(key id)
{
    string s = "[PNS] Route:";
    integer n = llGetListLength(route);
    integer i;
    for (i = 0; i < n; i += 4)
    {
        string region = llList2String(route, i);
        integer ias = llList2Integer(route, i + 1);
        integer alt = llList2Integer(route, i + 2);
        integer hdg = llList2Integer(route, i + 3);

        s += "\n" + (string) (i / 4) + ": " + region + " - IAS " + gps2str(ias) + " - ALT " + gps2str(alt) + " - HDG " + gps2str(hdg);
    }
    llRegionSayTo(id, 0, s);
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

default
{
    state_entry()
    {
        llOwnerSay("[PNS] Free Memory: " + (string) llGetFreeMemory());
        llListen(0, "", "", "");
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (!(id == pilot || id == copilot))
        {
            return;
        }

        list tokens = llParseString2List(message, [" "], []);
        integer num_tokens = llGetListLength(tokens);

        if (num_tokens == 0)
        {
            return;
        }
        
        if (llToLower(llList2String(tokens, 0)) == "pns")
        {
            if (num_tokens == 1)
            {
                active = !active;
                if (active)
                {
                    announce("Activated");
                    adjust();
                }
                else
                {
                    announce("Deactivated");
                }
            }
            else {
                string command = llToLower(llList2String(tokens, 1));

                if (command == "add")
                {
                    integer ias = str2gps(llList2String(tokens, 2));
                    integer alt = str2gps(llList2String(tokens, 3));
                    integer hdg = str2gps(llList2String(tokens, 4));

                    string region = llToUpper(llDumpList2String(llList2List(tokens, 5, -1), " "));

                    route += [region, ias, alt, hdg];
                    adjust();

                    announce("Added " + region + "  IAS " + gps2str(ias) + "  ALT " + gps2str(alt) + "  HDG " + gps2str(hdg));
                }
                else if (command == "list")
                {
                    list_route(id);
                }
                else if (command == "new")
                {
                    route = [];
                    announce("Route cleared.");
                }
                else if (command == "rev")
                {
                    reverse_route();
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
                    integer ias = str2gps(llList2String(tokens, 3));
                    integer alt = str2gps(llList2String(tokens, 4));
                    integer hdg = str2gps(llList2String(tokens, 5));
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

                    announce("Added " + region + "  IAS " + gps2str(ias) + "  ALT " + gps2str(alt) + "  HDG " + gps2str(hdg) + " on line " + (string) line);
                }
                else if (command == "stored")
                {
                    string text = "[PNS] Stored routes:";
                    list keys = llLinksetDataFindKeys(stored_route_prefix, 0, 0);
                    integer n = llGetListLength(keys);
                    integer i;
                    for (i = 0; i < n; ++i)
                    {
                        text += "\n" + llGetSubString(llList2String(keys, i), llStringLength(stored_route_prefix), -1);
                    }
                    llRegionSayTo(id, 0, text);
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
                    integer ias = str2gps(llList2String(tokens, 0));
                    integer alt = str2gps(llList2String(tokens, 1));
                    integer hdg = str2gps(llList2String(tokens, 2));
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
            llRemoveInventory(notecard);
        }
    }

    link_message(integer sender, integer num, string str, key id)
    {
        if (num == 126)
        {
            pilot = id;
            announce("Registered " + llGetUsername(pilot) + " as pilot.");
        }
        else if (num == 145)
        {
            copilot = id;
            announce("Registered " + llGetUsername(copilot) + " as copilot.");
        }
    }
}
