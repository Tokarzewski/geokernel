from geokernel import Face, Point

struct FacePair(Movable):
    var above: List[Face]
    var below: List[Face]

    def __init__(out self):
        self.above = List[Face]()
        self.below = List[Face]()

    def __init__(out self, *, deinit take: Self):
        self.above = take.above^
        self.below = take.below^

def get_faces() -> FacePair:
    var result = FacePair()
    return result^

def main() raises:
    var result = get_faces()
    print("len above:", len(result.above))
    print("len below:", len(result.below))
