---
description: 新しいCoworkプラグインをゼロから作成する
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, TodoWrite
argument-hint: [plugin-name-or-description]
---

plugin-creatorエージェントを使って新しいCoworkプラグインを作成する。

$ARGUMENTSが指定されている場合、それをプラグインの名前または概要のヒントとしてエージェントに伝える。
指定がない場合は、エージェントのディスカバリーフェーズで何を作るかをユーザーにヒアリングする。
