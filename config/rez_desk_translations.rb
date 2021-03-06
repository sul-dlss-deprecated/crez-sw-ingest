# contains translation hashes for rez_desk to building_facet value, and rez_desk to rez_location_facet
module RezDeskTranslations

  # from reserve desk value to building_facet value
  REZ_DESK_2_BLDG_FACET = {
    "ART-RESV" => "Art & Architecture (Bowes)",
    # "BIO-RESV" => "Biology (Falconer)", closed 12/2016
    "BUS-RESV" => "Business",
    # "CHEM-RESV" => "Chemistry & ChemEng (Swain)", closed 12/2016
    "E-RESV" => nil,   # no change?
    "EARTH-RESV" => "Earth Sciences (Branner)",
    "EAS-RESV" => "East Asia",
    "EDU-RESV" => "Education (Cubberley)",
    "ENG-RESV" => "Engineering (Terman)",
    "GREEN-RESV" => "Green",
    "HOOV-RESV" => "Hoover Library",
    "HOP-RESV" => "Marine Biology (Miller)",
    "LANG-RESV" => nil,  # Sarah Seestone says this is obsolete
    "LAW-RESV" => "Law (Crown)",
    # "MATH-RESV" => "Math & Statistics", closed 12/2016
    "MEDIA-RESV" => "Media & Microtext Center",
    "MEYER-RESV" => "Meyer",
    "MUSIC-RESV" => "Music",
#    "PHYS-RESV" => "Physics", No longer a Physics library
    "SCI-RESV" => "Science (Li and Ma)",
    "TANN-RESV" => "Philosophy (Tanner)"
  }

  # from reserve desk value to rez_location_facet value
  REZ_DESK_2_REZ_LOC_FACET = {
    "ART-RESV" => "Art Reserves",
    # "BIO-RESV" => "Falconer Reserves", closed 12/2016
    "BUS-RESV" => "Business Reserves",
    # "CHEM-RESV" => "Swain Reserves", closed 12/2016
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
    # "MATH-RESV" => "Math & Statistics Reserves", closed 12/2016
    "MEDIA-RESV" => "Media Reserves",
    "MEYER-RESV" => "Meyer Reserves",
    "MUSIC-RESV" => "Music Reserves",
    #"PHYS-RESV" => "Physics Reserves", No longer a Physics library
    "SCI-RESV" => "Science Reserves",
    "TANN-RESV" => "Tanner Reserves"
  }

end
