# FiyatRadar Repository Instructions

## First rule
Before making any UI/UX, layout, component, screen, navigation, spacing, typography, color, motion, or visual hierarchy decision, you MUST read:

- `docs/design-language.md`

Do not start designing before reading that file.

## Non-negotiable UI rule
This repository does NOT allow legacy UI reuse for new design work.

When a task is about redesigning or creating screens:
- do not preserve old layouts by default
- do not patch or polish an old screen unless the task explicitly says so
- do not reuse outdated widget trees as visual reference
- use old code only for business logic, models, providers, routing, and technical integration points
- treat the visual layer as replaceable unless explicitly told otherwise

## Design authority
`docs/design-language.md` is the single source of truth for:
- visual tone
- color behavior
- page hierarchy
- card language
- spacing rhythm
- typography hierarchy
- CTA behavior
- chips / pills / badges
- dark premium surfaces
- premium interaction tone

If a generated design conflicts with that document, the document wins.

## FiyatRadar product identity
FiyatRadar is a premium community-driven grocery price intelligence app.

It must NOT feel like:
- a cheap discount app
- a cluttered marketplace
- a generic fintech dashboard
- a gaming interface
- a noisy e-commerce screen

It MUST feel like:
- executive
- warm
- premium
- calm
- structured
- intentional

## Screen creation rule
When creating a new screen:
1. read `docs/design-language.md`
2. define the screen’s role in one sentence
3. define the primary user action
4. define the information hierarchy
5. then implement the UI

## Home screen rule
The home screen must not become a crowded card cemetery.
Keep one dominant hero area and controlled supporting sections.

## Reuse rule
Reuse business logic if needed.
Do not blindly reuse old presentation code.

## UX density rule
Do not overload the first viewport.
A screen can feel rich, but it must remain breathable and clear.

## Visual consistency rule
Every new screen must belong to the same approved visual family.
No screen should feel like it belongs to another app.

## Before finalizing any UI task
Check:
- Does this screen belong to the approved FiyatRadar visual language?
- Is the hierarchy clear at first glance?
- Is the screen premium but calm?
- Is there unnecessary density?
- Is gold used selectively instead of everywhere?
- Is there one dominant area and controlled supporting content?

If the answer is no, revise before finishing.