var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = CCNs","category":"page"},{"location":"#CCNs","page":"Home","title":"CCNs","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"CCNs is a package that standardizes manipulation of CMS Certification Numbers in Julia.","category":"page"},{"location":"","page":"Home","title":"Home","text":"CCNs uniquely identify health care providers and suppliers who interact with the United States Medicare and Medicaid programs, run out of the Centers of Medicare and Medicaid Services (CMS). CCNs are standardized in the State Operations Manual, CMS publication number 100-07.","category":"page"},{"location":"","page":"Home","title":"Home","text":"CCNs are sequences of alphanumeric characters. Health care providers are assigned 6-character CCNs, while health care suppliers are assigned 10-character CCNs. The canonical format used by this package to represent CCNs has the following structure:","category":"page"},{"location":"","page":"Home","title":"Home","text":"CCNs are strings represented as sequences of UTF-8 characters.\nOnly characters in the Latin Alphabet: Uppercase (U+0041 to U+005A) and ASCII Digits (U+0030 to U+0039) are used.\nThe first two characters always represent the State Code where the health care entity is officially located (note that \"State\" in this context includes countries, like Canada, and territories, like Guam).\nThe third character may designate the Facility Type or Supplier Type of the entity–otherwise, it is a part of the Sequence Number.\nThe fourth character may designate the Parent Facility Type for entities that are subunits of other facilities–otherwise, it is a part of the Sequence Number.\nThe fifth character is always a part of the Sequence Number.\nThe sixth character may designate the Emergency Hospital Type–otherwise, it is a part of the Sequence Number.\nThe seventh through tenth characters are only used for Suppliers, and are always part of the Sequence Number.","category":"page"},{"location":"#Types","page":"Home","title":"Types","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Because the structure of the CCN depends on the type of provider, supplier, or facility it is describing, this package defines separate types to help the user be precise about what kind of CCN the identifier represents. The types are described below:","category":"page"},{"location":"#Parsing","page":"Home","title":"Parsing","text":"","category":"section"},{"location":"#Constructors","page":"Home","title":"Constructors","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"You can create CCNs by calling the constructors of the concrete CCN types directly. This method of construction does no error checking: any AbstractString passed to the constructor is assumed to be valid. Use this method when:","category":"page"},{"location":"","page":"Home","title":"Home","text":"You need to process CCNs as quickly as possible;\nYou already know what type of facility the CCNs represent; and\nYou know that the CCNs are already in canonical format.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Examples:","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> c1 = MedicareProviderCCN(\"123456\")\nMedicareProviderCCN(\"123456\")\n\njulia> c2 = MedicareProviderCCN(\"banana\") # invalid, but no error checking is performed\nMedicareProviderCCN(\"banana\")\n\njulia> c3 = MedicareProviderCCN(\"12345678\") # too many characters to fit in String7, exception thrown\nERROR: ArgumentError: string too large (8) to convert to InlineStrings.String7\n[...]","category":"page"},{"location":"","page":"Home","title":"Home","text":"This package also implements Base.convert(::Type{<:CCN}, ::AbstractString), which simply passes the argument to the type constructor.","category":"page"},{"location":"#Base.parse","page":"Home","title":"Base.parse","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"You can create CCNs by parsing AbstractString values using Base.parse(::Type{<:CCN}, ::AbstractString). This method performs rudimentary checks on the input AbstractString and will throw an exception if it cannot possibly represent the given CCN type. Use this method when:","category":"page"},{"location":"","page":"Home","title":"Home","text":"You already know what type of facility the CCNs represent; and\nYou have strings that need to be converted into canonical format.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Examples:","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> parse(MedicareProviderCCN, \"123456\")\nMedicareProviderCCN(\"123456\")\n\njulia> parse(MedicareProviderCCN, \"123\") # valid values, but not in canonical format\nMedicareProviderCCN(\"000123\")\n\njulia> parse(MedicareProviderCCN, \"\\t12-p456\\n\") # common to find dashes and lower-case letters in some representations\nMedicareProviderCCN(\"12P456\")\n\njulia> parse(MedicareProviderCCN, \"1234567\") # small enough to fit in String7, but too many characters for CCN\nERROR: ArgumentError: CCN cannot be more than 6 characters in length\n[...]","category":"page"},{"location":"","page":"Home","title":"Home","text":"This method relies on the clean_ccn method, which is also exported for use.","category":"page"},{"location":"#ccn-method","page":"Home","title":"ccn method","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"You can create CCNs by automatically detecting the type based on the format of the code using the ccn(::AbstractString) method. There is no ambiguity in CCN types as long as the CCN is in canonical format. Use this method when:","category":"page"},{"location":"","page":"Home","title":"Home","text":"You do not know the type of CCN represented by the code;\nYou are willing to sacrifice the processing time needed to convert the string to canonical format; and\nYou are not concerned about type-stable code.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Examples:","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> ccn(\"123456\")\nMedicareProviderCCN(\"123456\")\n\njulia> ccn(\"12A456\")\nMedicaidOnlyProviderCCN(\"12A456\")\n\njulia> ccn(\"\\t12-p456\\n\")\nMedicareProviderCCN(\"12P456\")\n\njulia> ccn(\"X1234567\") # too long to be a provider CCN, but canonicallizes to a valid supplier CCN\nSupplierCCN(\"00X1234567\")\n\njulia> ccn(\"12I456\") # looks right, but is not a valid provider CCN\nERROR: ArgumentError: CCN type cannot be inferred from '12I456'\n[...]","category":"page"},{"location":"","page":"Home","title":"Home","text":"The package also exports ccn(::Type{<:CCN}, ::AbstractString), which is type-stable and can be used like parse(::Type{<:CCN}, ::AbstractString) (in fact, parse just calls ccn under the hood). You can also pass numbers to ccn, but because most CCN types require an alphabetic character somewhere in the string, you can only convert numbers to MedicareProviderCCN types:","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> ccn(123456)\nMedicareProviderCCN(\"123456\")\n\njulia> ccn(Float64(123)) # non-integers can be used if they can be exactly converted into integers\nMedicareProviderCCN(\"000123\")\n\njulia> ccn(-12345) # negative numbers are not allowed\nERROR: ArgumentError: CCNs cannot be negative\n[...]\n\njulia> ccn(1234567) # numbers with more than 6 digits are not allowed\nERROR: ArgumentError: CCN cannot be more than 6 characters in length\n[...]","category":"page"},{"location":"","page":"Home","title":"Home","text":"The ccn method relies on infer_ccn_type, which is also exported for convenience.","category":"page"},{"location":"#Inspecting","page":"Home","title":"Inspecting","text":"","category":"section"},{"location":"#Manipulating","page":"Home","title":"Manipulating","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [CCNs]","category":"page"},{"location":"#CCNs.INVALID_FACILITY_TYPE","page":"Home","title":"CCNs.INVALID_FACILITY_TYPE","text":"INVALID_FACILITY_TYPE\n\nA String representing an invalid facility type code for a given CCN type.\n\n\n\n\n\n","category":"constant"},{"location":"#CCNs.INVALID_STATE","page":"Home","title":"CCNs.INVALID_STATE","text":"INVALID_STATE\n\nA String representing an invalid state code.\n\n\n\n\n\n","category":"constant"},{"location":"#CCNs.CCN","page":"Home","title":"CCNs.CCN","text":"CCN\n\nA representation of a CMS Certification Number.\n\nCCNs are a uniform way of identifying providers or suppliers who currently or who ever have participated in the Medicare or Medicaid programs. A CCN is a 6- or 10-character alphanumeric string that encodes the provider or supplier's (respectively) State and facility type.\n\nCCNs can be constructed from AbstractString or Integer objects, but Integers can only represent a subset of all possible CCNs. For the most performant parsing of stored data, directly construct the known CCN type using constructor calls like MedicareProviderCCN(s). For slightly less performance, use ccn(T<:CCN, s) or parse(T<:CCN, s) to canonicalize the format of s and perform simple error checking. To infer what type of CCN a given value represents, use infer_ccn_type(s).\n\nCCNs inherit from AbstractString, so methods like length, get, etc. are all defined and work as if the CCN were a string identifier.\n\nCCNs are defined by CMS Manual System publication number 100-07 \"State Operations Provider Certification\".\n\n\n\n\n\n","category":"type"},{"location":"#CCNs.EmergencyHospitalCCN","page":"Home","title":"CCNs.EmergencyHospitalCCN","text":"EmergencyHospitalCCN\nEmergencyHospitalCCN(n::AbstractString)\n\nA type representing a designated Emergency Hospital provider.\n\nEmergency Hospital providers use six-character identifiers with the following format:\n\nSSQQQE\n\nWhere:\n\nSS represent a two-character alphanumeric State Code;\nE represents an alphabetical Emergency Hospital Type Code;\nQQQ represents a three-digit Sequence Number.\n\nThe constructor performs no error checking, but will throw an exception if n has more than seven characters.\n\n\n\n\n\n","category":"type"},{"location":"#CCNs.IPPSExcludedProviderCCN","page":"Home","title":"CCNs.IPPSExcludedProviderCCN","text":"IPPSExcludedProviderCCN\nIPPSExcludedProviderCCN(n::AbstractString)\n\nA type representing a Medicare or Medicaid provider excluded from the Inpatient Prospective Payment System (IPPS).\n\nIPPS-Excluded providers use six-character identifiers with the following format:\n\nSSTAQQ\n\nWhere:\n\nSS represent a two-character alphanumeric State Code;\nT represents an alphabetical Facility Type Code;\nA represents either an alphabetical Parent Facility Type Code (for IPPS-Excluded units of IPPS-Excluded parent facilities) or the most significant digit of the Sequence Number;\nQQ represents the two least significant digits of the Sequence Number.\n\nnote: Note\nIPPS-Excluded providers are always subunits of parent facilities, and as such they are not assigned their own CCN Sequence Number. The Sequence Number in the CCN will match the least significant digits of the parent facility.\n\nThe constructor performs no error checking, but will throw an exception if n has more than seven characters.\n\n\n\n\n\n","category":"type"},{"location":"#CCNs.MedicaidOnlyProviderCCN","page":"Home","title":"CCNs.MedicaidOnlyProviderCCN","text":"MedicaidOnlyProviderCCN\nMedicaidOnlyProviderCCN(n::AbstractString)\n\nA type representing a Medicaid-Only provider.\n\nMedicid-Only providers use six-character identifiers with the following format:\n\nSSTQQQ\n\nWhere:\n\nSS represent a two-character alphanumeric State Code;\nT represents an alphabetical Facility Type Code;\nQQQ represents a three-digit Sequence Number.\n\nThe constructor performs no error checking, but will throw an exception if n has more than seven characters.\n\n\n\n\n\n","category":"type"},{"location":"#CCNs.MedicareProviderCCN","page":"Home","title":"CCNs.MedicareProviderCCN","text":"MedicareProviderCCN\nMedicareProviderCCN(n::AbstractString)\n\nA type representing a Medicare provider.\n\nMedicare providers use six-character identifiers with the following format:\n\nSSPQQQ\n\nWhere:\n\nSS represent a two-character alphanumeric State Code;\nP represents either an a literal 'P' character (for Organ Procurement Organizations) or the most significant digit of the Sequence Number;\nQQQ represents the three least significant digits of the Sequence Number.\n\nThe constructor performs no error checking, but will throw an exception if n has more than seven characters.\n\n\n\n\n\n","category":"type"},{"location":"#CCNs.ProviderCCN","page":"Home","title":"CCNs.ProviderCCN","text":"ProviderCCN\n\nAn abstract type representing the various provider types that can be represented by a CCN.\n\nAll ProviderCCNs use 6-character identifiers.\n\n\n\n\n\n","category":"type"},{"location":"#CCNs.SupplierCCN","page":"Home","title":"CCNs.SupplierCCN","text":"SupplierCCN\nSupplierCCN(n::AbstractString)\n\nA type representing a Medicare or Medicaid Supplier.\n\nSuppliers use ten-character identifiers with the following format:\n\nSSTQQQQQQQ\n\nWhere:\n\nSS represent a two-character alphanumeric State Code;\nT represents a Supplier Type Code;\nQQQQQQQ represents a seven-digit Sequence Number.\n\nThe constructor performs no error checking, but will throw an exception if n has more than 15 characters.\n\n\n\n\n\n","category":"type"},{"location":"#CCNs.ccn","page":"Home","title":"CCNs.ccn","text":"ccn([T::Type], s) -> CCN\n\nConstruct a CCN from input s.\n\nArguments\n\nT::Type (optional) - The type of the CCN. If no type is given, the best guess of the type will be made based on the format of the input s using infer_ccn_type.\ns::Union{AbstractString,Integer} - The input to parse to create the CCN.\n\nReturn value\n\nReturns a CCN of concrete type T if given, else the type will be inferred from format of s.\n\n\n\n\n\n","category":"function"},{"location":"#CCNs.clean_ccn","page":"Home","title":"CCNs.clean_ccn","text":"clean_ccn(s; max_length=6) -> String\n\nClean the given value s and return a String in canonical CCN format.\n\nCanonical CCN format is a string of uppercase alphanumeric characters left-padded with zeros to either 6 or 10 characters. Some datasets allow CCNs to have a hyphen in position 2 separating the state code from the facility code, and some store the alphabetical characters in lower case.\n\nArguments\n\ns::Union{Integer,AbstractString} - The value to clean.\nmax_length::Integer = 6 - The maximum (and pad) length of the CCN. Should be either 6 (for providers) or 10 (for suppliers). Strings shorter than this length will be left-padded with zeros to this length.\n\nReturn\n\nThe canonicalized form of s.\n\n\n\n\n\n","category":"function"},{"location":"#CCNs.decode","page":"Home","title":"CCNs.decode","text":"decode([io::IO], ccn)\n\nDecode ccn and either return the information as a String or print to io.\n\n\n\n\n\n","category":"function"},{"location":"#CCNs.facility_type","page":"Home","title":"CCNs.facility_type","text":"facility_type(ccn) -> String\n\nReturn a description of the facility type of ccn as a String.\n\nReturns CCNs.INVALID_FACILITY_TYPE if the facility type code is invalid for the CCN type.\n\n\n\n\n\n","category":"function"},{"location":"#CCNs.facility_type_code","page":"Home","title":"CCNs.facility_type_code","text":"facility_type_code(ccn) -> String\n\nReturn the facility type code of ccn as a String.\n\nThe facility type is dependent on the type of CCN, but usually involves the 3rd character of the code.\n\n\n\n\n\n","category":"function"},{"location":"#CCNs.infer_ccn_type-Tuple{AbstractString}","page":"Home","title":"CCNs.infer_ccn_type","text":"infer_ccn_type(s) -> T<:CCN\n\nInfer the type of the CCN from a string in canonical CCN format.\n\nArguments\n\ns::Union{AbstractString,Integer} - A string or integer value in canonical CCN format.\n\nReturn value\n\nThe inferred type, which will be a subtype of CCN. Throws if the type cannot be inferred from s.\n\nSee also clean_ccn to canonicalize a CCN string.\n\n\n\n\n\n","category":"method"},{"location":"#CCNs.sequence_number","page":"Home","title":"CCNs.sequence_number","text":"sequence_number(ccn) -> Int64\n\nDecode the sequence number from a given CCN.\n\nSequence numbers are sometimes indefinite. If this is the case, then only the decodable digits of the sequence number are returned (typically the last digits).\n\n\n\n\n\n","category":"function"},{"location":"#CCNs.state-Tuple{CCNs.CCN}","page":"Home","title":"CCNs.state","text":"state(ccn) -> String\n\nDecode the state code of ccn and return it as a String.\n\nThe first two characters of a CCN encode the \"state\" where the entity is located. \"State\" is interpreted loosely, as valid states include countries (like Canada) and territories (like (Guam).\n\nReturns CCNs.INVALID_STATE if the first two characters are not a valid state code.\n\n\n\n\n\n","category":"method"},{"location":"#CCNs.state_code-Tuple{CCNs.CCN}","page":"Home","title":"CCNs.state_code","text":"state_code(ccn) -> String\n\nReturn the state code of ccn (the first two characters) as a String.\n\n\n\n\n\n","category":"method"}]
}
