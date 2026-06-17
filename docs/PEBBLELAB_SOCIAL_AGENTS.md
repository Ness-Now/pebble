# PebbleLab Social Agents Vision

## Purpose

This document records the long-term direction for social agents in PebbleLab. It is a design memory, not an implementation plan for the current patch.

PebbleLab should eventually be able to run deterministic multi-agent simulations where agents communicate, remember interactions, cooperate, compete, and form social relationships.

## Not Implemented Yet

None of the social systems described here are implemented yet.

Current PebbleLab agents are abstract, immobile, and PebbleLab-only. They are not PebbleCore entities, do not pathfind, do not communicate, do not maintain memory, and do not have social relationships.

## Future Capabilities

Possible future capabilities:

- public messages;
- private messages;
- help requests;
- proposed exchanges;
- information sharing;
- cooperation;
- trust and distrust;
- friendship;
- betrayal;
- reputation;
- group formation;
- private planning;
- conflict;
- reconciliation.

If deception is added later, it should be explicit and measurable. Agents may eventually hide information, mislead others, or coordinate privately, but those behaviors should not appear accidentally as side effects of unclear systems.

## Possible Social Metrics

Potential metrics:

- `trustScore(agentA, agentB)`
- `friendshipScore(agentA, agentB)`
- `betrayalCount`
- `helpGiven`
- `helpReceived`
- `messagesSent`
- `privateMessagesSent`
- `cooperationCount`
- `conflictCount`
- `reputationScore`

The exact schema should wait until PebbleLab has stable agent memory and interaction events.

## Example Relationship Logic

Non-final examples:

- helping another agent can increase trust;
- helping without immediate benefit can increase friendship;
- betraying another agent can sharply reduce trust;
- communicating often can increase familiarity;
- refusing help can affect relationship state;
- successful cooperation can support group formation;
- repeated deception can damage reputation if discovered.

## Design Warning

Do not code social systems too early.

The safer order is:

1. agents exist;
2. agents observe;
3. agents perform simple abstract actions;
4. agents remember;
5. agents interact;
6. agents communicate;
7. only then add richer social relationships.

Social behavior should remain deterministic, logged, and explainable before any training or Python analysis is introduced.
