// partsearch.ks - additional part/partmodule searching functions
// MIT License
// https://github.com/maraketty/MARALib/

@lazyGlobal off.

run once "0:/MARALib/library/logtools.ks".

function combineLists {
    parameter list1 is list().
    parameter list2 is list().

    local joinedList is list().

    if list1:length >= 0 and list2:length >= 0 {
        from {
            local x is 0.
        } until x >= max(list1:length,list2:length) step {
            set x to x + 1.
        } do {
            if x < list1:length {
                joinedList:add(list1[x]).
            }
            if x < list2:length {
                joinedList:add(list2[x]).
            }
        }
    }

    return joinedList.
}

function modulesFromPartDubbed {
    parameter source.
    parameter searchTerm.

    log_("[QUERY]: " + source + " [FOR]: " + searchTerm).
    local modList is list().
    if source:istype("Part") {
        from {
            local x is 0.
        } until x >= source:allmodules:length step {
            set x to x + 1.
        } do {
            log_("[QUERY]: " + source + " : " + source:getmodulebyindex(x):name + " [FOR]: " + searchTerm, 3).
            if source:getmodulebyindex(x):name:contains(searchTerm) {
                log_("[FOUND]: PARTMODULE(" + source:getmodulebyindex(x):name + ")").
                modList:add(source:getmodulebyindex(x)).
            }
        }
    } else {
        log_("[ALERT]: " + source + " [IS NOT TYPE]: Part").
    }

    return modList.
}

function modulesDubbed {
    parameter source.
    parameter searchTerm.

    log_("[QUERY]: " + source + " [FOR]: " + searchTerm).
    local modList is list().
    if source:istype("Part") {
        return modulesFromPartDubbed().
    } else if source:istype("Vessel") {
        log_("[QUERY]: " + source:parts:length + " parts").
        for part in source:parts {
            set modList to combineLists(modList,modulesFromPartDubbed(part,searchTerm)).
        }
    } else {
        log_("[ALERT]: " + source + " [IS NOT TYPE]: Part, Vessel", 1).
    }

    return modList.
}