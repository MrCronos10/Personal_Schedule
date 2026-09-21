"""Build HSKWordList.json: membership from leonsilicon/hsk2.0, glosses from drkameleon."""
import json

HAND_WRITTEN = {
    "弹钢琴": ("tán gāngqín", "to play the piano"),
    "百分之": ("bǎi fēn zhī", "percent"),
    "冰激凌": ("bīng jī líng", "ice cream"),
    "名胜古迹": ("míng shèng gǔ jì", "scenic spots and historical sites"),
    "后背": ("hòu bèi", "the back (of the body)"),
    "拼音": ("pīn yīn", "pinyin; phonetic transcription"),
    "模特": ("mó tè", "model (fashion)"),
    # CC-CEDICT gives these a sense HSK 4/5 doesn't mean, or none at all.
    "咸": ("xián", "salty"),
    "重": ("zhòng", "heavy; important"),
    "空": ("kōng", "empty; (kòng) free time"),
    "亚洲": ("yà zhōu", "Asia"),
    "欧洲": ("ōu zhōu", "Europe"),
    "大厦": ("dà shà", "large building; mansion"),
    "纪录": ("jì lù", "record (in sport etc.)"),
    "呀": ("ya", "(particle expressing surprise or doubt)"),
    # Grammar entries: kept whole so they never match segmentation.
    "得（助动词）": ("děi", "must; have to (auxiliary verb)"),
    "等（助词）": ("děng", "etc.; and so on (particle)"),
}
GRAMMAR = {"得（助动词）", "等（助词）"}

defs = {e["simplified"]: e for e in json.load(open("complete.json"))}

# Meanings are a reminder while reading, not a dictionary entry.
GLOSS_LIMIT = 70


# CC-CEDICT carries more than glosses. A surname, a cross-reference or a
# "variant of" tells the student nothing about the word they just tapped.
NOT_A_GLOSS = (
    "surname ",
    "see ",
    "variant of",
    "old variant",
    "used in ",
    "abbr. for",
    "(Tw)",
)


def usable(meanings):
    """Drop what isn't a gloss. CC-CEDICT writes its place names and
    cross-references with hanzi inside the English — 'Youhao district of
    Yichun city 市, Heilongjiang' — which makes them easy to spot."""
    return [
        m
        for m in meanings
        if not m.lower().startswith(NOT_A_GLOSS)
        and not any("一" <= c <= "鿿" for c in m)
    ]


def readings(forms):
    """Group a word's forms by reading, keeping every sense of that reading
    together: 咸 is both 'all' and 'salty' under xián. The reading is shown
    lowercase — 刀 is dāo, and only CC-CEDICT's surname entry capitalises it."""
    grouped = {}
    for form in forms:
        pinyin = form["transcriptions"]["pinyin"]
        key = pinyin.lower()
        grouped.setdefault(key, [pinyin, []])[1].extend(form["meanings"])
    for key, pair in grouped.items():
        if not usable([pair[0]]) or pair[0][:1].isupper():
            # Keep the capitalised spelling only if every sense is a proper noun.
            if usable(pair[1]):
                pair[0] = key
    return [tuple(p) for p in grouped.values()]


def pick_reading(forms):
    """CC-CEDICT capitalises proper nouns and lists them first: 孙子 is 'Sun Tzu'
    before it is 'grandson'. Prefer an ordinary reading, and among those the one
    carrying the most real glosses — 重 is zhòng 'heavy' long before chóng."""
    candidates = readings(forms)
    ordinary = [r for r in candidates if not r[0][:1].isupper()] or candidates
    pinyin, meanings = max(ordinary, key=lambda r: len(usable(r[1])))
    return pinyin, usable(meanings) or meanings


def gloss(meanings):
    """First meanings, to a readable length, never fewer than one."""
    kept = meanings[:1]
    for meaning in meanings[1:2]:
        if len("; ".join(kept + [meaning])) <= GLOSS_LIMIT:
            kept.append(meaning)
    text = "; ".join(kept)
    if len(text) > GLOSS_LIMIT:
        text = text[:GLOSS_LIMIT].rsplit(" ", 1)[0].rstrip(",;") + "…"
    return text


out = []
for level in (4, 5):
    for line in open(f"leon{level}.txt"):
        word = line.strip()
        if not word:
            continue
        if word in HAND_WRITTEN:
            pinyin, english = HAND_WRITTEN[word]
        else:
            pinyin, meanings = pick_reading(defs[word]["forms"])
            english = gloss(meanings)
        entry = {"w": word, "p": pinyin, "e": english, "l": level}
        if word in GRAMMAR:
            entry["g"] = True
        out.append(entry)

assert len([e for e in out if e["l"] == 4]) == 600
assert len([e for e in out if e["l"] == 5]) == 1300
assert all(e["w"] and e["p"] and e["e"] for e in out)
assert len({e["w"] for e in out}) == len(out)

with open("HSKWordList.json", "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
print("wrote", len(out), "entries")
