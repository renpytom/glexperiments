import re


class ShaderPart(object):
    """
    This represents a part of a shader.

    `name`
        A string giving the name of the shader part. Names starting with an
        underscore or "renpy." are reserved for Ren'Py.

    `variables`
        The variables used by the shader part. These should be listed one per
        line, a storage (uniform, attribute, or varing) followed by a type,
        name, and semicolon. For example::

            variables='''
            uniform sampler2D uTex0;
            attribute vec2 aTexCoord;
            varying vec2 vTexCoord;
            '''

    Other keyword arguments should start with ``vertex_`` or ``fragment_``,
    and end with an integer priority. So "fragment_120" or "vertex_30". These
    give text that's placed in the appropriate shader at the given priority,
    with lower priority numbers being insiderted before highter priority
    numbers.
    """

    def __init__(self, name, variables="", **kwargs):

        self.name = name

        # A list of priority, text pairs for each section of the vertex and fragment shaders.
        self.vertex_parts = [ ]
        self.fragment_parts = [ ]

        # Sets of (storage, type, name) tuples, where storage is one of 'uniform', 'attribute', or 'varying',
        self.vertex_variables = set()
        self.fragment_variables = set()

        # A sets of variable names used in the vertex and fragments shader.
        vertex_used = set()
        fragment_used = set()

        for k, v in kwargs.iteritems():

            shader, _, priority = k.partition('_')

            if not priority:
                # Trigger error handling.
                shader = None

            try:
                priority = int(priority)
            except:
                shader = None

            if shader == "vertex":
                parts = self.vertex_parts
                used = vertex_used
            elif shader == "fragment":
                parts = self.fragment_parts
                used = fragment_used
            else:
                raise Exception("Keyword arguments to ShaderPart must be of the form {vertex,fragment}_{priority}.")

            parts.append((priority, v))

            for m in re.finditer(r'\b\w+\b', v):
                used.add(m.group(0))

        for l in variables.split("\n"):
            l = l.strip(' ;')

            a = l.split()
            if not a:
                continue

            if len(a) != 3:
                print("Unknown shader variable line {!r}. Only the form '{{uniform,attribute,vertex}} {{type}} {{name}} is allowed.".format(l))

            a = tuple(a)
            name = a[2]

            if name in vertex_used:
                self.vertex_variables.add(a)

            if name in fragment_used:
                self.fragment_variables.add(a)


ShaderPart("renpy.geometry", variables="""
    uniform mat4 uTransform;
    attribute vec4 aPosition;
""", vertex_100="""
    gl_Position = vec4(aPosition.xyz, 1) * uTransform;
""")

ShaderPart("renpy.texture", variables="""
    uniform sampler2D uTex0;
    attribute vec2 aTexCoord;
    varying vec2 vTexCoord;
""", vertex_110="""
    vTexCoord = aTexCoord;
""", fragment_110="""
    gl_FragColor = texture2D(uTex0, vTexCoord.xy);
""")
