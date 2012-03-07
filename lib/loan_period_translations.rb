# Map Loan Period Codes to User Friendly String
module LoanPeriodTranslations
  LOAN_CODE_2_USER_STR = {
    "2H" => "2 Hours",
    "3H" => "3 Hours",
    "MED3H" => "3 Hours",
    "4H" => "4 Hours",
    "24H" => "24 Hours",
    "1DND" => "1 Day",
    "1DND-RES" => "1 Day",
    "2D-RES" => "2 Days",
    "3D-RES" => "3 Days",
    "7D" => "7 Days",
    "7D-RES" => "7 Days",
    "14D" => "14 Days",
    "28D" => "28 Days",
    "365DAYS" => "1 Year",
    "NON-CIRC" => "In-Library Use Only",
    "E-ACCESS" => nil,  # electronic has no useful loan period
  }
end 
