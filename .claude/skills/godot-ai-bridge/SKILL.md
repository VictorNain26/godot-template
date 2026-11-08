---
name: godot-ai-bridge
description: Réparer ou mettre à jour le pont MCP godot-ai entre Claude Code (WSL) et l'éditeur Windows. À utiliser quand les outils godot-ai manquent dans la session, quand `tests/test_mcp_pin.gd` échoue, ou après une mise à jour de `addons/godot_ai`.
---

# Pont godot-ai

`.mcp.json` lance `godot-ai attach` avec le `uvx.exe` de Windows, car le pont ne parle qu'au serveur local de l'éditeur. Ses arguments sont ceux que le dock Godot AI de l'éditeur Windows écrit pour Claude Code Windows.

- **Après une mise à jour de l'addon**, ou si `tests/test_mcp_pin.gd` échoue (version épinglée qui ne suit plus `addons/godot_ai`) : reprendre ces arguments, puis redémarrer la session.
- **Si les outils manquent** : lire le log dans `~/.cache/claude-cli-nodejs/<projet>/mcp-logs-godot-ai/`. Un `uvx.exe` qui refuse une option des arguments se met à jour sous Windows avec l'installeur officiel de uv. Sinon, demander à l'utilisateur.
- **Si ce lancement direct casse** : il n'est pas celui que documente godot-ai. Pour WSL face à un éditeur Windows, la voie supportée est SSH (section « Agents on another machine or in a container » de `docs/client-configuration.md` du dépôt hi-godot/godot-ai).
