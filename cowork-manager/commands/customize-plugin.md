---
description: 既存のCoworkプラグインをカスタマイズする
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, TodoWrite
argument-hint: [plugin-name]
---

plugin-customizerエージェントを使って既存のCoworkプラグインをカスタマイズする。

$ARGUMENTSが指定されている場合、それをカスタマイズ対象のプラグイン名として扱い、エージェントに渡す。
指定がない場合は、エージェントがどのプラグインをカスタマイズするかをユーザーに確認する。
