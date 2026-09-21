"""Build PersonalSchedule/Vocabulary/HSKWordList.json.

Run from this directory after `fetch-sources.sh`, which pins the upstream commits:

    ./fetch-sources.sh && python3 build-word-list.py

Three sources, each for one job. See PersonalSchedule/Vocabulary/SOURCE.md.

  membership  leonsilicon/hsk2.0          which words are at which level
  readings    clem109/hsk-vocabulary      the pinyin and senses HSK means
  fallback    drkameleon/complete-hsk...  words clem109 doesn't carry

Why clem109 decides the reading: a third of HSK 4/5 is single characters, and
CC-CEDICT lists every reading of a character with no idea which one HSK means.
Picking one from CC-CEDICT alone gets 圈 as juān rather than quān and 切 as qiè
rather than qiē — a wrong pinyin teaches the student the wrong word, and they
then bank three Clean Sightings on it. clem109's lists are already per-HSK-level,
so somebody has already chosen the reading.
"""
import json
import re

GLOSS_LIMIT = 70

# Where no source carries the word, or carries only a sense HSK 4/5 does not mean.
# Every single character here was checked by hand against its HSK sense.
HAND_WRITTEN = {
    # Not in any source.
    "弹钢琴": ("tán gāngqín", "to play the piano"),
    "百分之": ("bǎi fēn zhī", "percent"),
    "冰激凌": ("bīng jī líng", "ice cream"),
    "名胜古迹": ("míng shèng gǔ jì", "scenic spots and historical sites"),
    "后背": ("hòu bèi", "the back (of the body)"),
    "拼音": ("pīn yīn", "pinyin; phonetic transcription"),
    "模特": ("mó tè", "model (fashion)"),
    "升": ("shēng", "litre; to rise"),
    "胡同": ("hú tòng", "lane; alley"),
    # Ambiguous single characters that fall through to the CC-CEDICT fallback.
    "停": ("tíng", "to stop; to park"),
    "刚": ("gāng", "just now; only a moment ago"),
    "照": ("zhào", "to shine; to take (a photo)"),
    "空": ("kōng", "empty; (kòng) free time"),
    "赶": ("gǎn", "to catch up; to hurry"),
    "转": ("zhuǎn", "to turn; to change"),
    "占": ("zhàn", "to occupy; to take up"),
    "划": ("huà", "to draw (a line); to plan"),
    "抓": ("zhuā", "to grab; to catch"),
    "碰": ("pèng", "to bump into; to meet"),
    "签": ("qiān", "to sign; label"),
    "滑": ("huá", "slippery; to slide"),
    "靠": ("kào", "to lean on; to rely on"),
    "首": ("shǒu", "head; classifier for songs and poems"),
    "追": ("zhuī", "to chase; to pursue"),
    "戒": ("jiè", "to give up (a habit); to guard against"),
    "挣": ("zhèng", "to earn (money); to struggle free"),
    "咸": ("xián", "salty"),
    "重": ("zhòng", "heavy; important"),
    "台": ("tái", "platform; classifier for machines"),
    "克": ("kè", "gram"),
    "朝": ("cháo", "towards; dynasty"),
    "朵": ("duǒ", "classifier for flowers and clouds"),
    "干": ("gàn", "to do; to work"),
    "之": ("zhī", "(literary possessive particle); him; her; it"),
    "亚洲": ("yà zhōu", "Asia"),
    "欧洲": ("ōu zhōu", "Europe"),
    "大厦": ("dà shà", "large building; mansion"),
    "纪录": ("jì lù", "record (in sport etc.)"),
    "呀": ("ya", "(particle expressing surprise or doubt)"),
    # Grammar entries: the annotation is part of the word, so they never match a
    # word split out of an Article. See SOURCE.md.
    "得（助动词）": ("děi", "must; have to (auxiliary verb)"),
    "等（助词）": ("děng", "etc.; and so on (particle)"),
}
GRAMMAR = {"得（助动词）", "等（助词）"}

# CC-CEDICT and clem109 both carry more than glosses. A surname, a cross-reference
# or a classifier note tells the student nothing about the word they just tapped.
NOT_A_GLOSS = (
    "surname ",
    "see ",
    "variant of",
    "old variant",
    "used in ",
    "abbr. for",
    "(tw)",
    "cl:",
)


def has_hanzi(text):
    return any("一" <= c <= "鿿" for c in text)


def balanced(text):
    return text.count("(") == text.count(")")


def rejoin(meanings):
    """clem109 split its senses on commas, including the commas inside a bracket:
    'to hold (a meeting, ceremony etc)' arrives as two fragments. Put them back
    together rather than throwing away a perfectly good gloss."""
    out, held = [], None
    for meaning in meanings:
        held = meaning if held is None else f"{held}, {meaning}"
        if balanced(held):
            out.append(held)
            held = None
    if held is not None:
        out.append(held)
    return out


def usable(meanings):
    """Drop what isn't a gloss. CC-CEDICT writes its place names and cross-references
    with hanzi inside the English — 'Youhao district of Yichun city 市, Heilongjiang' —
    which makes them easy to spot. clem109 splits its senses on commas, which leaves
    fragments with an opening bracket and no close; those go too."""
    return [
        m.strip()
        for m in meanings
        if m.strip()
        and not m.strip().lower().startswith(NOT_A_GLOSS)
        and not has_hanzi(m)
        and balanced(m)
    ]


def gloss(meanings):
    """One or two senses, to a readable length. A tapped word gets a reminder, not a
    dictionary entry."""
    kept = meanings[:1]
    for meaning in meanings[1:2]:
        if len("; ".join(kept + [meaning])) <= GLOSS_LIMIT:
            kept.append(meaning)
    text = "; ".join(kept)
    if len(text) > GLOSS_LIMIT:
        # Cut at a word, then drop a parenthetical left hanging open.
        text = text[:GLOSS_LIMIT].rsplit(" ", 1)[0].rstrip(",;")
        if not balanced(text):
            text = text[: text.rindex("(")].strip().rstrip(",;")
        text += "…"
    return text


def load_membership():
    """leonsilicon decides what is in the list. Its six levels total exactly 5,000,
    which is the HSK 2.0 standard; the other repos have drifted."""
    return [
        (word.strip(), level)
        for level in (4, 5)
        for word in open(f"sources/leon{level}.txt")
        if word.strip()
    ]


def load_readings():
    """clem109, every level, first spelling wins."""
    readings = {}
    for level in (1, 2, 3, 4, 5, 6):
        for entry in json.load(open(f"sources/clem{level}.json")):
            readings.setdefault(
                entry["hanzi"], (entry["pinyin"], entry["translations"])
            )
    return readings


def load_fallback():
    """drkameleon, for words clem109 doesn't carry. Only reached by unambiguous
    multi-syllable words: every ambiguous single character is in HAND_WRITTEN."""
    fallback = {}
    for entry in json.load(open("sources/complete.json")):
        form = entry["forms"][0]
        fallback.setdefault(
            entry["simplified"],
            (form["transcriptions"]["pinyin"], form["meanings"]),
        )
    return fallback


def main():
    membership = load_membership()
    readings = load_readings()
    fallback = load_fallback()

    out, from_fallback = [], []
    for word, level in membership:
        if word in HAND_WRITTEN:
            pinyin, english = HAND_WRITTEN[word]
        elif word in readings:
            pinyin, meanings = readings[word]
            english = gloss(usable(rejoin(meanings)))
        elif word in fallback:
            pinyin, meanings = fallback[word]
            english = gloss(usable(meanings))
            from_fallback.append(word)
        else:
            raise SystemExit(f"no reading for {word}; add it to HAND_WRITTEN")
        if not english:
            raise SystemExit(f"no usable gloss for {word}; add it to HAND_WRITTEN")
        entry = {"w": word, "p": pinyin, "e": english, "l": level}
        if word in GRAMMAR:
            entry["g"] = True
        out.append(entry)

    assert len([e for e in out if e["l"] == 4]) == 600, "HSK 4 must hold 600 words"
    assert len([e for e in out if e["l"] == 5]) == 1300, "HSK 5 must hold 1,300 words"
    assert len({e["w"] for e in out}) == len(out), "no word may appear twice"
    assert all(e["w"] and e["p"] and e["e"] for e in out)
    assert all(balanced(e["e"]) for e in out), "a gloss was cut mid-bracket"
    assert not any(has_hanzi(e["e"]) for e in out), "a gloss carries hanzi"

    with open("../../PersonalSchedule/Vocabulary/HSKWordList.json", "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    print(f"wrote {len(out)} entries")
    print(f"  hand-written: {sum(1 for e in out if e['w'] in HAND_WRITTEN)}")
    print(f"  from clem109: {len(out) - len(from_fallback) - sum(1 for e in out if e['w'] in HAND_WRITTEN)}")
    print(f"  from drkameleon fallback: {len(from_fallback)}")
    single = [w for w in from_fallback if len(w) == 1]
    if single:
        print(f"  !! single characters via fallback, check these by hand: {' '.join(single)}")


if __name__ == "__main__":
    main()
