<div align="center">

# PiBlock 

![Java](https://img.shields.io/badge/Java-21-blue?style=for-the-badge&logo=openjdk&logoColor=white)
![Platform](https://img.shields.io/badge/Raspberry_Pi-5-c51a4a?style=for-the-badge&logo=raspberrypi&logoColor=white)
![License](https://img.shields.io/badge/Llicència-MIT-yellow?style=for-the-badge)
![Status](https://img.shields.io/badge/Estat-Actiu-green?style=for-the-badge)

![Velocity](https://img.shields.io/badge/Velocity-Proxy-09add3?style=flat-square&logo=velocity&logoColor=white)
![Geyser](https://img.shields.io/badge/Geyser-Bedrock-2ecc71?style=flat-square&logo=geyser&logoColor=white)
![Paper](https://img.shields.io/badge/Paper-Server-F44336?style=flat-square&logo=papermc&logoColor=white)

**Servidors Minecraft per a Instituts: Fàcil, Ràpid i complert**

</div>

---

## 📌 Què és això?

**PiBlock** és un sistema que converteix una petita **Raspberry Pi 5** en un servidor professional de Minecraft.

La seva màgia és que permet jugar a tothom, sense importar si tenen un ordinador potent (Java) o juguen des del mòbil o la consola (Bedrock). Tot està integrat i funciona automàticament.

---

## 🏗️ Com funciona tècnicament?

A sota pots veure exactament com viatgen les paquets des de els clients fins al servidor.

```mermaid
flowchart TB
 subgraph subGraph0["Clients (Internet)"]
        J["Java Client (PC)<br>(TCP)"]
        B["Bedrock Client (Consola/Mobil)<br>(UDP)"]
        T["Tunnel Playit.gg<br>(IP diferent depenent del client)"]
  end
 subgraph subGraph1["Servidor (RP5)"]
    direction TB
        V["VELOCITY PROXY<br>Port: 25565 (TCP)<br>[Autenticacio i Gestio]"]
        G["GEYSER BRIDGE<br>Port: 19132 (UDP)<br>[Traduccio de Protocol]"]
        P["PAPER SERVER<br>Port: 30066 (TCP)<br>[Joc Principal]"]
        L["LIMBO SERVER<br>Port: 30000 (TCP)<br>[Fallback]"]
  end
    J == Connexio Estandard ==> T
    B -. Connexio Consola/Mobil .-> T
    T == Trafic Java ==> V
    T -. Trafic Bedrock .-> G
    G == |Traduccio de Paquets| ==> V
    V == Jugador Autenticat ==> P
    V -. Si Paper cau o reinicia .-> L

    L@{ shape: rect}
     J:::client
     B:::client
     T:::internet
     V:::velocity
     G:::geyser
     P:::paper
     L:::limbo
    classDef client fill:#2c3e50,stroke:white,color:white,stroke-width:2px
    classDef internet fill:#5b3fd6,stroke:white,color:white,stroke-width:2px
    classDef velocity fill:#09add3,stroke:white,color:white,stroke-width:4px
    classDef geyser fill:#2ecc71,stroke:white,color:white,stroke-width:2px
    classDef paper fill:#F44336,stroke:white,color:white,stroke-width:2px
    classDef limbo fill:#AFB42B,stroke:white,color:white,stroke-width:2px
    style subGraph1 stroke:#2962FF
```


---
## Instalació

- --L'instalació automatica encara esta sent desenvolupada--
  
## 🚀 Com engegar-ho

Per a engegar-ho has d'anar a "https://piblock.cat/panel".

- Un cop en en panell has d'iniciar sessio amb les credencials que et proporcionem.
- Anar a l'apartat de servidors.
- Engegar manualment els 4 servidors.

---

## 👥 Equip de PiBlock

**Creat amb passió.**

[![Contribs](https://contrib.rocks/image?repo=dimova5/PiBlock)](https://github.com/dimova5/PiBlock/graphs/contributors)

<div align="center">
    <sub>Distribuït sota <b>MIT License</b></sub>
</div>
