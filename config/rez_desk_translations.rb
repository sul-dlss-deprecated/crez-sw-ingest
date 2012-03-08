# contains translation hashes for rez_desk to building_facet value, and rez_desk to rez_location_facet
module RezDeskTranslations

  # from reserve desk value to building_facet value
  REZ_DESK_2_BLDG_FACET = {
    "ART-RESV" => "Art & Architecture",
    "BIO-RESV" => "Falconer (Biology)",
    "CHEM-RESV" => "Swain (Chemistry & Chem. Engineering)",
    "E-RESV" => nil,   # no change?
    "EARTH-RESV" => "Branner (Earth Sciences & Maps)",
    "EAS-RESV" => "East Asia",
    "EDU-RESV" => "Cubberley (Education)",
    "ENG-RESV" => "Engineering",
    "GREEN-RESV" => "Green (Humanities & Social Sciences)",
    "HOOV-RESV" => "Hoover Library",
    "HOP-RESV" => "Miller (Hopkins Marine Station)",
    "LANG-RESV" => nil,  # Sarah Seestone says this is obsolete
    "LAW-RESV" => "Crown (Law)",
    "MATH-RESV" => "Mathematics & Statistics",
    "MEDIA-RESV" => "Green (Humanities & Social Sciences)",
    "MEYER-RESV" => "Meyer",
    "MUSIC-RESV" => "Music",
    "PHYS-RESV" => "Physics",
    "TANN-RESV" => "Tanner (Philosophy Dept.)"
  }

  # from reserve desk value to rez_location_facet value
  REZ_DESK_2_REZ_LOC_FACET = {
    "ART-RESV" => "Art Reserves",
    "BIO-RESV" => "Falconer Reserves",
    "CHEM-RESV" => "Swain Reserves",
    "E-RESV" => nil,   # no change?  "E-Reserves"
    "EARTH-RESV" => "Branner Reserves",
    "EAS-RESV" => "East Asia Reserves",
    "EDU-RESV" => "Cubberley Reserves",
    "ENG-RESV" => "Engineering Reserves",
    "GREEN-RESV" => "Green Reserves",
    "HOOV-RESV" => "Hoover Reserves",
    "HOP-RESV" => "Miller Reserves",
    "LANG-RESV" => nil,  # Sarah Seestone says this is obsolete
    "LAW-RESV" => "Law Reserves",
    "MATH-RESV" => "Math & Statistics Reserves",
    "MEDIA-RESV" => "Media-Microtext (Green) Reserves",
    "MEYER-RESV" => "Meyer Reserves",
    "MUSIC-RESV" => "Music Reserves",
    "PHYS-RESV" => "Physics Reserves",
    "TANN-RESV" => "Tanner Reserves"
  }

end