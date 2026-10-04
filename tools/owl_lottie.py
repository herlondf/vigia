"""Gera os Lottie do mascote (coruja) a partir do rig SVG.

Uso: python tools/owl_lottie.py <vigia-rig.svg> <pasta-saida>

Cada <path> do rig vira uma forma Lottie; as peças são agrupadas (cabeça,
olhos, pupilas, bico, orelhas) e cada estado do assistente anima esses grupos.
Saída: assistant-<estado>.json (mesmos nomes que o assistente já carrega).
"""
import json
import re
import sys
import xml.etree.ElementTree as ET

NS = '{http://www.w3.org/2000/svg}'
FPS = 30
SIZE = 512
OWL_SCALE = 3.2          # 128 unidades do rig -> ~410 px; cabe no círculo do FAB
OWL_CENTER = (64, 66)    # centro visual da coruja no rig


# ── SVG path -> Lottie shape ────────────────────────────────────────────────

TOKEN = re.compile(r'[MmCcSsLlHhVvZz]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?')


def parse_path(d):
    """Devolve a lista de vértices [(ponto, in_rel, out_rel)] e se é fechado."""
    toks = TOKEN.findall(d)
    i = 0
    cmd = None
    cur = (0.0, 0.0)
    start = (0.0, 0.0)
    last_c2 = None
    nodes = []  # cada nó: [x, y, ix, iy, ox, oy]
    closed = False

    def num():
        nonlocal i
        v = float(toks[i]); i += 1
        return v

    def add_cubic(p0, c1, c2, p3):
        nodes[-1][4] = c1[0] - p0[0]
        nodes[-1][5] = c1[1] - p0[1]
        nodes.append([p3[0], p3[1], c2[0] - p3[0], c2[1] - p3[1], 0.0, 0.0])

    def add_line(p3):
        nodes.append([p3[0], p3[1], 0.0, 0.0, 0.0, 0.0])

    while i < len(toks):
        t = toks[i]
        if re.match(r'[A-Za-z]', t):
            cmd = t; i += 1
            if cmd in 'Zz':
                closed = True
                cur = start
                continue
        rel = cmd.islower()
        c = cmd.upper()
        ox, oy = cur if rel else (0.0, 0.0)
        if c == 'M':
            p = (num() + ox, num() + oy)
            cur = start = p
            nodes.append([p[0], p[1], 0.0, 0.0, 0.0, 0.0])
            cmd = 'l' if rel else 'L'  # pares seguintes são linhas
            last_c2 = None
        elif c == 'C':
            c1 = (num() + ox, num() + oy); c2 = (num() + ox, num() + oy); p3 = (num() + ox, num() + oy)
            add_cubic(cur, c1, c2, p3); last_c2 = c2; cur = p3
        elif c == 'S':
            c1 = (2 * cur[0] - last_c2[0], 2 * cur[1] - last_c2[1]) if last_c2 else cur
            c2 = (num() + ox, num() + oy); p3 = (num() + ox, num() + oy)
            add_cubic(cur, c1, c2, p3); last_c2 = c2; cur = p3
        elif c == 'L':
            p3 = (num() + ox, num() + oy); add_line(p3); cur = p3; last_c2 = None
        elif c == 'H':
            x = num() + (cur[0] if rel else 0.0); p3 = (x, cur[1]); add_line(p3); cur = p3; last_c2 = None
        elif c == 'V':
            y = num() + (cur[1] if rel else 0.0); p3 = (cur[0], y); add_line(p3); cur = p3; last_c2 = None
        else:
            raise ValueError('comando não suportado: ' + cmd)

    # Fechado e o último ponto coincide com o primeiro: funde os dois.
    if closed and len(nodes) > 1:
        a, b = nodes[0], nodes[-1]
        if abs(a[0] - b[0]) < 0.05 and abs(a[1] - b[1]) < 0.05:
            a[2], a[3] = b[2], b[3]
            nodes.pop()
    return nodes, closed


def shape(nodes, closed):
    r = lambda v: round(v, 3)
    return {'ty': 'sh', 'ks': {'a': 0, 'k': {
        'c': closed,
        'v': [[r(n[0]), r(n[1])] for n in nodes],
        'i': [[r(n[2]), r(n[3])] for n in nodes],
        'o': [[r(n[4]), r(n[5])] for n in nodes]}}}


def hex_rgb(h):
    h = h.lstrip('#')
    return [round(int(h[k:k + 2], 16) / 255, 4) for k in (0, 2, 4)]


def fill(color):
    return {'ty': 'fl', 'c': {'a': 0, 'k': hex_rgb(color) + [1]}, 'o': {'a': 0, 'k': 100}, 'r': 1}


def stroke(color, width):
    return {'ty': 'st', 'c': {'a': 0, 'k': hex_rgb(color) + [1]}, 'o': {'a': 0, 'k': 100},
            'w': {'a': 0, 'k': width}, 'lc': 2, 'lj': 2}


# ── animação ────────────────────────────────────────────────────────────────

def static(v):
    return {'a': 0, 'k': v}


def anim(keys):
    """keys: [(frame, valor)]; easing suave entre todos."""
    if len(keys) == 1:
        return static(keys[0][1])
    out = []
    for f, v in keys:
        v = v if isinstance(v, list) else [v]
        out.append({'t': f, 's': v, 'i': {'x': [0.45], 'y': [1]}, 'o': {'x': [0.55], 'y': [0]}})
    return {'a': 1, 'k': out}


def tr(pivot=(0, 0), p=None, s=None, r=None, o=None):
    """Transform de grupo; p/s/r/o: valor fixo ou lista de keyframes."""
    def prop(v, default):
        if v is None:
            return static(default)
        if isinstance(v, list) and v and isinstance(v[0], tuple):
            return anim(v)
        return static(v)
    return {'ty': 'tr',
            'a': static(list(pivot)),
            'p': prop(p, list(pivot)),
            's': prop(s, [100, 100]),
            'r': prop(r, 0),
            'o': prop(o, 100),
            'sk': static(0), 'sa': static(0)}


def group(name, items, transform):
    return {'ty': 'gr', 'nm': name, 'it': items + [transform]}


def ellipse(cx, cy, w, h):
    return {'ty': 'el', 'p': static([cx, cy]), 's': static([w, h])}


def poly(points, closed=False):
    return shape([[x, y, 0, 0, 0, 0] for x, y in points], closed)


# ── rig ─────────────────────────────────────────────────────────────────────

def load_rig(path):
    root = ET.parse(path).getroot()
    parts = {}
    grads = {}
    for el in root:
        tag = el.tag.replace(NS, '')
        if tag == 'linearGradient':
            stops = []
            for st in el:
                stops.append((float(st.get('offset')), st.get('stop-color')))
            grads[el.get('id')] = (float(el.get('x1')), float(el.get('y1')),
                                   float(el.get('x2')), float(el.get('y2')), stops)
        elif tag == 'path':
            n = int(el.get('id').split('_')[-1])
            nodes, closed = parse_path(el.get('d'))
            f = el.get('fill')
            if f.startswith('url('):
                x1, y1, x2, y2, stops = grads[f[5:-1]]
                g = []
                for off, col in stops:
                    g += [off] + hex_rgb(col)
                paint = {'ty': 'gf', 'o': static(100), 'r': 1, 't': 1,
                         's': static([x1, y1]), 'e': static([x2, y2]),
                         'g': {'p': len(stops), 'k': static(g)}}
            else:
                paint = fill(f)
            parts[n] = [shape(nodes, closed), paint]
    return parts


def part(parts, n):
    return group('p%02d' % n, parts[n], tr())


def build(parts, st):
    """Monta a árvore de grupos com os movimentos do estado st (dict)."""
    P = lambda *ns: [part(parts, n) for n in ns]

    def look(cx, cy):
        # 'look': deslocamento do olhar [(frame, [dx, dy])], igual nos dois olhos.
        keys = st.get('look')
        return None if keys is None else [(f, [cx + d[0], cy + d[1]]) for f, d in keys]
    pupil_r = group('pupila-d', P(17), tr((79, 42), p=look(79, 42)))
    pupil_l = group('pupila-e', P(18), tr((48, 41), p=look(48, 41)))
    eye_r = group('olho-d', [pupil_r] + P(15), tr((79, 42), s=st.get('eye')))
    eye_l = group('olho-e', [pupil_l] + P(16), tr((48, 41), s=st.get('eye')))
    beak_low = group('bico', P(19), tr((64, 47), s=st.get('beak')))
    beak = group('bico-todo', P(20) + [beak_low], tr((64, 47)))
    ear_r = group('orelha-d', P(2), tr((92, 26), r=st.get('ear_r'), s=st.get('ears')))
    ear_l = group('orelha-e', P(3), tr((36, 26), r=st.get('ear_l'), s=st.get('ears')))
    lids = []
    if st.get('lids') is not None:
        for cx, cy in ((79, 42), (48, 41)):
            arc = shape([[cx - 7, cy, 0, 0, 3, 4.5], [cx + 7, cy, -3, 4.5, 0, 0]], False)
            lids.append(group('palpebra', [arc, stroke('#303232', 1.9)], tr((cx, cy), o=st.get('lids'))))
    # Lottie desenha o primeiro item por cima.
    head = group('cabeca', lids + [beak, eye_r, eye_l] + P(9, 8, 7) + [ear_r, ear_l],
                 tr((64, 62), p=st.get('head_p'), r=st.get('head_r')))
    belly = group('barriga', P(14, 13, 12, 11, 10, 6, 5), tr())
    owl = group('coruja', [head, belly] + P(1),
                tr((64, 120), p=st.get('owl_p'), s=st.get('owl_s'), r=st.get('owl_r')))
    perch = group('poleiro', P(4), tr())
    extras = st.get('extras', [])
    return extras + [owl, perch]


def lottie(name, frames, shapes):
    cx, cy = OWL_CENTER
    layer = {
        'ddd': 0, 'ind': 1, 'ty': 4, 'nm': 'coruja', 'sr': 1, 'ao': 0,
        'ks': {'o': static(100), 'r': static(0),
               'p': static([SIZE / 2, SIZE / 2]), 'a': static([cx, cy]),
               's': static([OWL_SCALE * 100, OWL_SCALE * 100])},
        'shapes': shapes, 'ip': 0, 'op': frames, 'st': 0, 'bm': 0}
    return {'v': '5.7.4', 'fr': FPS, 'ip': 0, 'op': frames, 'w': SIZE, 'h': SIZE,
            'nm': 'vigia-' + name, 'ddd': 0, 'assets': [], 'layers': [layer]}


# ── estados ─────────────────────────────────────────────────────────────────

def blink(at, base=100):
    return [(at, [100, base]), (at + 3, [100, 8]), (at + 6, [100, base])]


def breathe(frames, amp=1.5):
    return [(0, [100, 100]), (frames // 2, [100 + amp / 3, 100 + amp]), (frames, [100, 100])]


def z_letter(x, y, size, delay, frames):
    """'Z' que sobe e some."""
    pts = [(x, y), (x + size, y), (x, y + size), (x + size, y + size)]
    item = [poly(pts), stroke('#8e7cc3', 2.2)]
    p = [(delay, [0, 0]), (delay + 40, [6, -14]), (frames, [6, -14])]
    o = [(0, 0), (delay, 0), (delay + 8, 100), (delay + 34, 100), (delay + 42, 0), (frames, 0)]
    return group('z', item, tr((x, y), p=[(f, [x + v[0], y + v[1]]) for f, v in p], o=o))


def dot(x, y, delay, frames):
    o = [(0, 30), (delay, 30), (delay + 8, 100), (delay + 20, 30), (frames, 30)]
    p = [(0, [x, y]), (delay, [x, y]), (delay + 8, [x, y - 3]), (delay + 16, [x, y]), (frames, [x, y])]
    return group('ponto', [ellipse(0, 0, 7, 7), fill('#f2a35b')], tr((0, 0), p=p, o=o))


def magnifier(frames):
    lens = [ellipse(0, 0, 18, 18), fill('#bfe3f5'), stroke('#263238', 3)]
    handle = [poly([(6.5, 6.5), (14, 14)]), stroke('#263238', 4)]
    items = [group('vidro', lens, tr()), group('cabo', handle, tr())]
    path = [(0, [104, 76]), (frames // 2, [108, 70]), (frames, [104, 76])]
    return group('lupa', items, tr((0, 0), p=path, r=[(0, -8), (frames // 2, 6), (frames, -8)]))


def warning(frames):
    tri = [poly([(0, -10), (11, 9), (-11, 9)], True), fill('#ffb300')]
    bang = [poly([(0, -4), (0, 3)]), stroke('#3e2723', 2.6)]
    pt = [ellipse(0, 6.2, 2.4, 2.4), fill('#3e2723')]
    s = [(0, [0, 0]), (8, [118, 118]), (14, [100, 100]), (frames, [100, 100])]
    return group('alerta', [group('excl', bang, tr()), group('pt', pt, tr())] + tri,
                 tr((0, 0), p=[104, 18], s=s))


def drop(frames):
    """Gota de suor escorrendo do lado da cabeça (preocupação)."""
    item = [shape([[0, -6, 0, 0, 3, 4], [0, 4, 3, 0, -3, 0]], True), fill('#7cc4f5')]
    p = [(0, [100, 22]), (frames * 2 // 3, [102, 40]), (frames, [102, 40])]
    o = [(0, 0), (6, 100), (frames * 2 // 3 - 6, 100), (frames * 2 // 3, 0), (frames, 0)]
    return group('gota', item, tr((0, 0), p=p, o=o))


def red_alert(frames):
    """Balão vermelho com '!' pulsando."""
    circle = [ellipse(0, 0, 18, 18), fill('#e53935')]
    bang = [poly([(0, -5), (0, 2)]), stroke('#ffffff', 2.6)]
    pt = [ellipse(0, 5.5, 2.6, 2.6), fill('#ffffff')]
    s = [(0, [100, 100]), (frames // 4, [118, 118]), (frames // 2, [100, 100]),
         (3 * frames // 4, [118, 118]), (frames, [100, 100])]
    return group('alerta', [group('excl', bang, tr()), group('pt', pt, tr())] + circle,
                 tr((0, 0), p=[106, 18], s=s))


def clock(frames):
    """Relogiozinho com o ponteiro girando (prazo perto)."""
    face = [ellipse(0, 0, 18, 18), fill('#fff8e1'), stroke('#f2a35b', 2.4)]
    hour = [poly([(0, 0), (0, -4.5)]), stroke('#6e4f44', 2)]
    minute = group('min', [poly([(0, 0), (6, 0)]), stroke('#6e4f44', 1.6)],
                   tr((0, 0), r=[(0, 0), (frames, 360)]))
    wob = [(0, -6), (frames // 2, 6), (frames, -6)]
    return group('relogio', [minute, group('hora', hour, tr())] + face,
                 tr((0, 0), p=[106, 30], r=wob))


def sparkle(x, y, delay, frames, size=7):
    """Estrelinha de 4 pontas que acende e some."""
    k = size / 7
    pts = [(0, -7 * k), (1.6 * k, -1.6 * k), (7 * k, 0), (1.6 * k, 1.6 * k),
           (0, 7 * k), (-1.6 * k, 1.6 * k), (-7 * k, 0), (-1.6 * k, -1.6 * k)]
    s = [(0, [0, 0]), (delay, [0, 0]), (delay + 8, [110, 110]), (delay + 16, [0, 0]), (frames, [0, 0])]
    return group('brilho', [poly(pts, True), fill('#feb903')], tr((0, 0), p=[x, y], s=s))


STATES = {
    # Parado, mais vivo: respira, pisca, olha para os lados, inclina e dá um pulinho.
    'idle': (180, lambda f: {
        'owl_s': [(0, [100, 100]), (45, [100, 101.5]), (90, [100, 100]), (135, [100, 101.5]), (f, [100, 100])],
        'eye': [(0, [100, 100])] + blink(36) + blink(118) + [(f, [100, 100])],
        'look': [(0, [0, 0]), (52, [0, 0]), (58, [-2, 0.5]), (78, [-2, 0.5]), (84, [2, 0.5]),
                 (104, [2, 0.5]), (110, [0, 0]), (f, [0, 0])],
        'head_r': [(0, 0), (56, 0), (62, -4), (80, -4), (86, 4), (104, 4), (110, 0), (f, 0)],
        'ear_r': [(0, 0), (20, -9), (26, 0), (140, 0), (146, -9), (152, 0), (f, 0)],
        'ear_l': [(0, 0), (150, 9), (156, 0), (f, 0)],
        'owl_p': [(0, [64, 120]), (160, [64, 120]), (166, [64, 115]), (172, [64, 120]), (f, [64, 120])],
    }),
    # Tem issue atrasada: preocupada, tremendo de leve, suando, com alerta vermelho.
    'idle-overdue': (90, lambda f: {
        'owl_s': breathe(f, 1),
        'eye': [116, 116],
        'look': [(0, [0, 0]), (20, [-1.5, 0]), (40, [1.5, 0]), (60, [-1.5, 0]), (f, [0, 0])],
        'owl_p': [(0, [64, 120]), (4, [63, 120]), (8, [65, 120]), (12, [64, 120]),
                  (48, [64, 120]), (52, [63, 120]), (56, [65, 120]), (60, [64, 120]), (f, [64, 120])],
        'ears': [(0, [100, 108]), (f, [100, 108])],
        'extras': [red_alert(f), drop(f)],
    }),
    # Prazo perto: olha para o relógio de vez em quando, inquieta.
    'idle-duesoon': (120, lambda f: {
        'owl_s': breathe(f),
        'eye': [(0, [100, 100])] + blink(90) + [(f, [100, 100])],
        'look': [(0, [0, 0]), (20, [2, -1]), (50, [2, -1]), (58, [0, 0]), (f, [0, 0])],
        'head_r': [(0, 0), (20, 6), (50, 6), (58, 0), (f, 0)],
        'extras': [clock(f)],
    }),
    # Novidade chegou: pulinhos, orelhas em pé, brilhos.
    'news': (60, lambda f: {
        'owl_p': [(0, [64, 120]), (8, [64, 112]), (16, [64, 120]), (24, [64, 115]), (32, [64, 120]), (f, [64, 120])],
        'owl_s': [(0, [100, 100]), (14, [104, 96]), (18, [100, 100]), (30, [102, 98]), (34, [100, 100]), (f, [100, 100])],
        'ears': [(0, [100, 100]), (8, [100, 122]), (40, [100, 122]), (f, [100, 100])],
        'eye': [(0, [100, 100]), (8, [112, 112]), (40, [112, 112]), (f, [100, 100])],
        'extras': [sparkle(100, 14, 4, f), sparkle(28, 20, 12, f, 6), sparkle(108, 44, 20, f, 5)],
    }),
    'sleepy': (120, lambda f: {
        'owl_s': breathe(f, 3),
        'eye': [100, 0],
        'lids': 100,
        'head_p': [64, 64],
        'head_r': [(0, 0), (f // 2, 3), (f, 0)],
        'extras': [z_letter(98, 26, 7, 0, f), z_letter(104, 16, 9, 40, f)],
    }),
    'listening': (90, lambda f: {
        'owl_s': breathe(f),
        'head_r': [(0, 0), (14, -7), (70, -7), (f, 0)],
        'ears': [(0, [100, 100]), (12, [100, 114]), (76, [100, 114]), (f, [100, 100])],
        'look': [(0, [0, 0]), (14, [1.5, 1]), (70, [1.5, 1]), (f, [0, 0])],
        'eye': [(0, [100, 100])] + blink(44) + [(f, [100, 100])],
    }),
    'thinking': (90, lambda f: {
        'owl_s': breathe(f),
        'head_r': [(0, 0), (16, 5), (74, 5), (f, 0)],
        'look': [(0, [0, 0]), (14, [1.5, -2.5]), (44, [-1.5, -2.5]), (74, [1.5, -2.5]), (f, [0, 0])],
        'extras': [dot(94, 14, 0, f), dot(101, 8, 10, f), dot(108, 2, 20, f)],
    }),
    'acting': (60, lambda f: {
        'owl_p': [(0, [64, 120]), (f // 4, [64, 118]), (f // 2, [64, 120]), (3 * f // 4, [64, 118]), (f, [64, 120])],
        'look': [(0, [-1.5, 0]), (f // 2, [1.5, 0]), (f, [-1.5, 0])],
        'extras': [magnifier(f)],
    }),
    'speaking': (40, lambda f: {
        'owl_s': breathe(f, 1),
        'beak': [(0, [100, 100]), (6, [100, 62]), (12, [100, 100]), (20, [100, 70]), (28, [100, 100]), (f, [100, 100])],
        'head_r': [(0, 0), (f // 2, 2.5), (f, 0)],
    }),
    'error': (45, lambda f: {
        'owl_p': [(0, [64, 120]), (3, [60, 120]), (6, [68, 120]), (9, [61, 120]), (12, [67, 120]),
                  (16, [63, 120]), (20, [64, 120]), (f, [64, 120])],
        'eye': [(0, [100, 100]), (6, [116, 116]), (f, [116, 116])],
        'ears': [(0, [100, 100]), (6, [100, 120]), (f, [100, 120])],
        'extras': [warning(f)],
    }),
}


def main():
    rig, out = sys.argv[1], sys.argv[2]
    parts = load_rig(rig)
    for name, (frames, spec) in STATES.items():
        doc = lottie(name, frames, build(parts, spec(frames)))
        with open('%s/assistant-%s.json' % (out, name), 'w', encoding='utf-8') as fh:
            json.dump(doc, fh, separators=(',', ':'))
        print(name, frames)


if __name__ == '__main__':
    main()
