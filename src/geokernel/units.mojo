from geokernel import FType
from std.collections import Dict
from std.math import pi


struct Units:
    var conversions: Dict[String, Dict[String, FType]]

    def __init__(out self) raises:
        self.conversions = Dict[String, Dict[String, FType]]()
        self.conversions["rad"] = Dict[String, FType]()
        self.conversions["rad"]["deg"] = 180 / pi

        self.conversions["deg"] = Dict[String, FType]()
        self.conversions["deg"]["rad"] = pi / 180

    def convert(mut self, from_u: String, to_u: String, v: FType) raises -> FType:
        return self.conversions[from_u][to_u] * v
