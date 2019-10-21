from array import array


class Clip(object):

    def __init__(self, a, b):

        self.a = array('f', a)
        self.a_points = len(a) / 2
        self.a_stride = 2

        self.b = array('f', b)
        self.b_points = len(b) / 2
        self.b_stride = 2

        self.clip_all_planes()

    def clip_all_planes(self):
        index = (self.a_points - 1) * self.a_stride
        a0x = self.a[index]
        a0y = self.a[index+1]

        index = 0

        while index < self.a_points * self.a_stride:
            a1x = self.a[index]
            a1y = self.a[index + 1]

            print((a0x, a0y), "->", (a1x, a1y))

            index += self.a_stride
            a0x = a1x
            a0y = a1y

    def clip_on_plane(self, ax, ay, bx, by):
        clip_x = bx - ax
        clip_y = by - ay

        index = 0


Clip(
    [0.0, 0.0,
     100.0, 0.0,
     100.0, 100.0,
     0.0, 100.0],

    [ 0.0, 150.0,
      5.0, 50.0,
      100.0, 150.0,
      ]

    )
