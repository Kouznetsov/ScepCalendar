local _, NS = ...
NS = NS or {}

local locale = GetLocale()

local esES = {
    january = "Enero",
    february = "Febrero",
    march = "Marzo",
    april = "Abril",
    may = "Mayo",
    june = "Junio",
    july = "Julio",
    august = "Agosto",
    september = "Septiembre",
    october = "Octubre",
    november = "Noviembre",
    december = "Diciembre",
    monday = "Lunes",
    tuesday = "Martes",
    wednesday = "Miércoles",
    thursday = "Jueves",
    friday = "Viernes",
    saturday = "Sábado",
    sunday = "Domingo",
    created_by = "Creado por ",
    create_new_event = "Crear un nuevo evento",
    sign_up = "Registrarse",
    sign_out = "Cerrar sesión",
    youre_signed_up_for_this_event = "Estás registrado para este evento",
    youre_not_signed_up_for_this_event = "No estás registrado para este evento",
    roster = "Lista",
    warriors = "Guerreros",
    paladins = "Paladines",
    hunters = "Cazadores",
    rogues = "Pícaros",
    mages = "Magos",
    priests = "Sacerdotes",
    druids = "Druidas",
    shamans = "Chamanes",
    warlocks = "Brujos",
    must_have_guild = "You have to be in a guild to  use ScepCalendar",
    create = "Create",
    create_event = "Create an event"
}

local frFR = {
    january = "Janvier",
    february = "Février",
    march = "Mars",
    april = "Avril",
    may = "Mai",
    june = "Juin",
    july = "Juillet",
    august = "Août",
    september = "Septembre",
    october = "Octobre",
    november = "Novembre",
    december = "Décembre",
    monday = "Lundi",
    tuesday = "Mardi",
    wednesday = "Mercredi",
    thursday = "Jeudi",
    friday = "Vendredi",
    saturday = "Samedi",
    sunday = "Dimanche",
    created_by = "Créé par ",
    create_new_event = "Créer un nouvel event",
    sign_up = "S'inscrire",
    sign_out = "Se désinscrire",
    youre_signed_up_for_this_event = "Tu es inscrit à cet event",
    youre_not_signed_up_for_this_event = "Tu n'es pas inscrit à cet event",
    roster = "Roster",
    warriors = "guerriers",
    paladins = "paladins",
    hunters = "chasseurs",
    rogues = "voleurs",
    mages = "mages",
    priests = "prêtres",
    druids = "druides",
    shamans = "chamans",
    warlocks = "démonistes",
    must_have_guild = "Vous devez être dans une guilde pour utiliser ScepCalendar",
    create = "Créer",
    create_event = "Créer un event"
}

local enUS = {
    january = "January",
    february = "February",
    march = "March",
    april = "April",
    may = "May",
    june = "June",
    july = "July",
    august = "August",
    september = "September",
    october = "October",
    november = "November",
    december = "December",
    monday = "Monday",
    tuesday = "Tuesday",
    wednesday = "Wednesday",
    thursday = "Thursday",
    friday = "Friday",
    saturday = "Saturday",
    sunday = "Sunday",
    created_by = "Created by ",
    create_new_event = "Create a new event",
    sign_up = "Sign up",
    sign_out = "Sign out",
    youre_signed_up_for_this_event = "You are signed up for this event",
    youre_not_signed_up_for_this_event = "You are not signed up for this event",
    roster = "Roster",
    warriors = "warriors",
    paladins = "paladins",
    hunters = "hunters",
    rogues = "rogues",
    mages = "mages",
    priests = "priests",
    druids = "druids",
    shamans = "shamans",
    warlocks = "warlocks",
    must_have_guild = "You have to be in a guild to  use ScepCalendar",
    create = "Create",
    create_event = "Create an event"
}

local translations = {
    frFR = frFR,
    enUS = enUS,
    enGB = enUS,
    esES = esES,
    esMX = esES
}

NS.translate = function(string)
    if translations[locale] then
        return translations[locale][string]
    else
        return translations[enUS][string]
    end
end