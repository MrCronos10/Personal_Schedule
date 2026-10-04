#!/usr/bin/env python3
"""Build PersonalSchedule/Vocabulary/TopicWordList.json from the hand-written
terms in this file.

The HSK list is drawn from three upstream repos pinned by `fetch-sources.sh`
(see .scratch/reading-and-vocabulary/). The Topic List is different: it is the
student's own topic, farming and fertilizer in Cambodia, and no public repo
carries that vocabulary with the right senses. So the terms are written here
by hand and this script's job is to turn them into the bundle format and
assert the shape before writing.

Run from the repo root:

    python3 .scratch/topic-list/build/build-topic-list.py
"""

from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[3]
OUT = ROOT / "PersonalSchedule" / "Vocabulary" / "TopicWordList.json"

# A gloss stays short — tapping a word returns a reminder, not a dictionary
# entry — and never contains a newline (the Article cache splits on \n).
GLOSS_LIMIT = 70

# (group id, Chinese group name, English group name)
GROUPS: list[tuple[str, str, str]] = [
    ("raw", "粪便与原料", "Manure and raw materials"),
    ("ferment", "堆肥与发酵", "Composting and fermentation"),
    ("soil", "养分与土壤", "Nutrients, soil and crops"),
    ("safety", "质量安全与检测", "Quality, safety and lab"),
    ("plant", "生产与机械", "Production and machinery"),
    ("trade", "市场与贸易", "Market and trade"),
]

# Each line is: word|pinyin|english. Senses are the ones the student will meet
# visiting a Chinese fertilizer factory and reading real production articles —
# not every dictionary sense a character carries.
TERMS: dict[str, str] = {
    "raw": """\
鸡粪|jī fèn|chicken manure
猪粪|zhū fèn|pig manure
牛粪|niú fèn|cattle manure
粪便|fèn biàn|excrement; manure
畜禽粪污|chù qín fèn wū|livestock and poultry manure waste
畜牧业|xù mù yè|animal husbandry
养殖场|yǎng zhí chǎng|breeding farm
养殖|yǎng zhí|to raise (animals); aquaculture
秸秆|jiē gǎn|crop straw
稻壳|dào ké|rice husk
锯末|jù mò|sawdust
垫料|diàn liào|bedding; litter
沼气|zhǎo qì|biogas
沼渣|zhǎo zhā|biogas residue
废弃物|fèi qì wù|waste material
污水|wū shuǐ|sewage; waste water
尿液|niào yè|urine
脱水|tuō shuǐ|to dewater; to dehydrate
""",
    "ferment": """\
堆肥|duī féi|compost
发酵|fā jiào|fermentation
腐熟|fǔ shú|to decompose to maturity (composting)
翻堆|fān duī|to turn the compost pile
好氧发酵|hào yǎng fā jiào|aerobic fermentation
厌氧发酵|yàn yǎng fā jiào|anaerobic fermentation
堆体|duī tǐ|compost pile
发酵槽|fā jiào cáo|fermentation trough
翻抛机|fān pāo jī|compost turner
菌剂|jūn jì|microbial inoculant
发酵菌|fā jiào jūn|fermentation bacteria
通风|tōng fēng|ventilation; aeration
曝气|pù qì|forced aeration
升温|shēng wēn|temperature rise
高温期|gāo wēn qī|high-temperature (thermophilic) stage
腐殖质|fǔ zhí zhì|humus
腐熟度|fǔ shú dù|degree of maturity
""",
    "soil": """\
土壤|tǔ rǎng|soil
农业|nóng yè|agriculture
作物|zuò wù|crop
种植|zhòng zhí|to plant; to grow
施肥|shī féi|to apply fertilizer
基肥|jī féi|base fertilizer
追肥|zhuī féi|top dressing
产量|chǎn liàng|yield
改良土壤|gǎi liáng tǔ rǎng|to improve soil
土壤酸化|tǔ rǎng suān huà|soil acidification
水稻|shuǐ dào|paddy rice
木薯|mù shǔ|cassava
橡胶|xiàng jiāo|rubber
胡椒|hú jiāo|pepper (the crop)
氮|dàn|nitrogen
磷|lín|phosphorus
钾|jiǎ|potassium
氮磷钾|dàn lín jiǎ|NPK (nitrogen, phosphorus, potassium)
碳氮比|tàn dàn bǐ|carbon-nitrogen ratio
有机质|yǒu jī zhì|organic matter
微生物|wēi shēng wù|microorganism
养分|yǎng fèn|nutrient
氨|ān|ammonia
酸碱度|suān jiǎn dù|pH
水分|shuǐ fèn|moisture
微量元素|wēi liàng yuán sù|trace elements
腐植酸|fǔ zhí suān|humic acid
""",
    "safety": """\
重金属|zhòng jīn shǔ|heavy metals
病原菌|bìng yuán jūn|pathogen
大肠杆菌|dà cháng gān jūn|E. coli
蛔虫卵|huí chóng luǎn|roundworm eggs
种子发芽指数|zhǒng zi fā yá zhǐ shù|seed germination index
含水率|hán shuǐ lǜ|moisture content
养分含量|yǎng fèn hán liàng|nutrient content
检测|jiǎn cè|to test; to detect
检测报告|jiǎn cè bào gào|test report
采样|cǎi yàng|sampling
标准|biāo zhǔn|standard
国家标准|guó jiā biāo zhǔn|national standard
肥料登记证|féi liào dēng jì zhèng|fertilizer registration certificate
抗生素|kàng shēng sù|antibiotic
残留|cán liú|residue
烧苗|shāo miáo|fertilizer burn (seedlings scorched)
无害化|wú hài huà|harmless treatment
臭味|chòu wèi|bad smell
""",
    "plant": """\
有机肥|yǒu jī féi|organic fertilizer
肥料|féi liào|fertilizer
化肥|huà féi|chemical fertilizer
复合肥|fù hé féi|compound fertilizer
肥料厂|féi liào chǎng|fertilizer factory
肥料生产|féi liào shēng chǎn|fertilizer production
生产线|shēng chǎn xiàn|production line
农业机械|nóng yè jī xiè|agricultural machinery
造粒|zào lì|granulation
造粒机|zào lì jī|granulator
颗粒|kē lì|granule; pellet
烘干|hōng gān|to dry (by heat)
烘干机|hōng gān jī|dryer
粉碎|fěn suì|to crush; to pulverise
粉碎机|fěn suì jī|crusher
搅拌|jiǎo bàn|to mix; to stir
搅拌机|jiǎo bàn jī|mixer
筛分|shāi fēn|to screen; to sieve
包装|bāo zhuāng|packaging
自动包装机|zì dòng bāo zhuāng jī|automatic packing machine
输送带|shū sòng dài|conveyor belt
固液分离|gù yè fēn lí|solid-liquid separation
""",
    "trade": """\
成本|chéng běn|cost
利润|lì rùn|profit
价格|jià gé|price
报价|bào jià|price quotation
供应商|gōng yìng shāng|supplier
经销商|jīng xiāo shāng|distributor
批发|pī fā|wholesale
订货|dìng huò|to place an order
样品|yàng pǐn|sample
考察|kǎo chá|to inspect; to visit and study
进口|jìn kǒu|to import
出口|chū kǒu|to export
关税|guān shuì|tariff
投资|tóu zī|to invest; investment
市场|shì chǎng|market
工厂|gōng chǎng|factory
设备|shè bèi|equipment
技术|jì shù|technology; technique
质量|zhì liàng|quality
营养|yíng yǎng|nutrition
农民|nóng mín|farmer
柬埔寨|jiǎn pǔ zhài|Cambodia
泰国|tài guó|Thailand
""",
}


def build() -> list[dict]:
    out: list[dict] = []
    seen: set[str] = set()
    group_ids = {g[0] for g in GROUPS}
    for group_id in TERMS:
        if group_id not in group_ids:
            sys.exit(f"unknown group id: {group_id}")
    for group_id, _, _ in GROUPS:
        lines = [line for line in TERMS[group_id].splitlines() if line.strip()]
        for line in lines:
            parts = line.split("|")
            if len(parts) != 3:
                sys.exit(f"bad line: {line!r}")
            word, pinyin, english = (p.strip() for p in parts)
            if not word or not pinyin or not english:
                sys.exit(f"missing field: {line!r}")
            if "\n" in english:
                sys.exit(f"gloss has a newline: {word}")
            if len(english) > GLOSS_LIMIT:
                sys.exit(f"gloss > {GLOSS_LIMIT}: {word}")
            if word in seen:
                sys.exit(f"duplicate: {word}")
            seen.add(word)
            out.append({"w": word, "p": pinyin, "e": english, "g": group_id})
    return out


def main() -> None:
    rows = build()
    # The totals the student watches: fixed so a tweak to the data can't quietly
    # move the denominator mid-year.
    expected_total = 125
    expected_per_group = {"raw": 18, "ferment": 17, "soil": 27, "safety": 18, "plant": 22, "trade": 23}
    if len(rows) != expected_total:
        sys.exit(f"total {len(rows)} != expected {expected_total}")
    counts: dict[str, int] = {}
    for row in rows:
        counts[row["g"]] = counts.get(row["g"], 0) + 1
    if counts != expected_per_group:
        sys.exit(f"group totals {counts} != expected {expected_per_group}")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    # Compact one-row-per-entry JSON, same shape as HSKWordList.json so iOS can
    # decode it with the same Row type if that path is ever shared.
    payload = "[" + ",".join(json.dumps(r, ensure_ascii=False) for r in rows) + "]"
    OUT.write_text(payload, encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)} — {len(rows)} rows")


if __name__ == "__main__":
    main()
