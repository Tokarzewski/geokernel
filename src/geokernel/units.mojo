from geokernel import FType
from collections import Dict
from math import pi


struct Units:
    var conversions: Dict[String, Dict[String, FType]]

    fn __init__(inout self) raises:
        self.conversions = Dict[String, Dict[String, FType]]()
        self.conversions["rad"] = Dict[String, FType]()
        self.conversions["rad"]["deg"] = 180 / pi

        self.conversions["deg"] = Dict[String, FType]()
        self.conversions["deg"]["rad"] = pi / 180

    def convert(inout self, from_u: String, to_u: String, v: FType) -> FType:
        return self.conversions[from_u][to_u] * v
