[Rotilio thermo - termostato open source](README.md) passo 1 di 7

## Componenti principali

### Sistema di riscaldamento

E' l'oggetto che andremo a controllare. Questo progetto funziona per tutti gli impianti di riscaldamento in cui esiste un termostato che apre o chiude un circuito collegato alla caldaia.
A seconda dei casi, la caldaia inizia a scaldare quando il circuito si chiude o si apre. Il progetto è compatibile con entrambi i tipi di caldaia.
Il collegamento quindi avviene tra il relè di Rotilio Maker e la caldaia.
Anche il tradizionale cronotermostato ha un relè, Rotilio Maker quindi si può sostituire al cronotermostato molto facilmente.
Ci sono due modi di collegare Rotilio Maker:

- sostituendo completamente il cronotermostato
- affiancandolo, con un collegamento in parallelo 

### App Mobile, versione 1

L'App Mobile è lo strumento che permette di interagire con il sistema. Deve presentare, almeno per iniziare, le seguenti funzionalità:

- Accensione e spegnimento manuale del riscaldamento, con regolazione della temperatura desiderata
- Indicazioni sullo stato attuale del sistema: temperatura, stato di marcia, connessione
- Possibilità di gestire più sistemi di riscaldamento (casa, ufficio, casa al mare, casa in montagna)

### App Mobile, versione 2

Consolidato il funzionamento di base potremo inserire funzionalità evolute nel nostro sistema, come ad esempio la programmazione del termostato con giorni della settimana, orari e temperature.

### Dispositivo IoT Rotilio Maker

[Rotilio Maker](https://techmakers.io/rotilio-maker.html) ospita il [sensore](https://it.wikipedia.org/wiki/Sensore) di temperatura che ci permette di capire se è il momento o meno di accendere la caldaia. Inoltre è presente un [relè](https://it.wikipedia.org/wiki/Rel%C3%A8) bistabile che funge da attuatore, inviando alla caldaia il comando di accensione o spegnimento.

### Particle Cloud

Il Cloud di [Particle.io](https://particle.io) è una componente utilissima perchè permette di gestire la connessione al dispositivo con estrema semplicità e in tutta sicurezza. Inoltre ci permetterà di aggiornare il firmware del dispositivo anche da remoto, per quei dispositivi già installati in loco, a cui vorremo inviare modifiche successive del software.

### Firmware

Il firmware è il programma che andremo ad inserire nella CPU del dispositivo IoT Rotilio Maker. Si occuperà di molti aspetti: comunicazione con il cloud, invio della temperatura e dello stato di funzionamento del sistema, ricezione dei comandi di accensione e spegnimento del riscaldamento.  


## Tecnologie

Tutto questo è possibile perchè le tecnologie impiegate sono semplici, facilmente disponibili (open source) e molto ben documentate.
Inoltre l'hardware è iper collaudato.

### Meteor

Per rendere il più universale possibile questo progetto abbiamo scelto di sviluppare il codice lato APP e lato SERVER totalmente in Javascript.

[Meteor](https://www.meteor.com) è il framework Javascript che attualmente presenta il compromesso migliore tra portabilità, velocità di sviluppo e affidabilità di esecuzione sul maggior numero di piattaforme.

### Paricle.io

[Particle.io](https://particle.io) è un ottimo partner per sviluppare dispositivi connessi. Tutte le problematiche di sicurezza, connessione e aggiornamento del dispositivo sono risolte direttamente nell'ecosistema messo a disposizione da questa (ormai ex) start-up Californiana, che produce software e dispositivi IoT.
Il codice che produrremo lato dispositivo (firmware) è scritto in Wiring(R), compatibile Arduino(R).

### Rotilio Maker

[Rotilio Maker](https://techmakers.io/rotilio-maker.html) è un prodotto IoT pensato per chi vuole realizzare progetti maker ma anche per chi vuole intraprendere il cammino di realizzazione di prodotti connessi, quindi lo abbiamo equipaggiato con componenti utili in molti progetti IoT, ma è possibile espanderlo a seconda delle esigenze.
Questo permette ad un qualunque sviluppatore di software di leggere una temperatura o attivare un relè, con una sola semplice chiamata https, come se si navigasse una pagina WEB.

Facciamo un esempio, tanto per entrare nel vivo.

Inseriamo nella barra degli indirizzi del browser questo [URL](https://api.particle.io/v1/devices/420026001147343339383037/status?access_token=89d67f062abf6d45aa95f176642479d7caf5ca3c):

```
https://api.particle.io/v1/devices/420026001147343339383037/status?access_token=89d67f062abf6d45aa95f176642479d7caf5ca3c
```

Otterremo la seguente risposta dal Rotilio Maker presente nel nostro laboratorio (se non dovesse rispondere, [mandateci una email](mailto:support@techmakers.io) o [chiamateci](tel:0108315289), ve lo accendiamo noi):

```
{
    "cmd": "VarReturn",
    "name": "status",
    "result": {
        "dimmer": 0,
        "temperature": 24,
        "exttemp": 24.39,
        "humidity": 68,
        "pressure": 1006.049988,
        "photoresistor": 4069,
        "trimmer": 2758,
        "deltalight": 1311,
        "button1": 0,
        "button2": 0,
        "switch": 0,
        "relais": 0,
        "alarm": 0
    },
    "coreInfo": {
        "last_app": "",
        "last_heard": "2017-09-16T12:02:34.553Z",
        "connected": true,
        "last_handshake_at": "2017-09-16T11:37:25.199Z",
        "deviceID": "420026001147343339383037",
        "product_id": 6
    }
}
```

### Breve panoramica sulle componenti che useremo in Rotilio Maker.

Rotilio Maker è provvisto di sensori di temperatura, umidità, pressione, luce, pulsanti, trimmer, relè buzzer, connettori di espansione e morsetti vari.

Le componenti che andremo ad utilizzare per questo progetto sono:

- Connettore di espansione per l'alloggiamento del Photon di Particle.io
- Morsetto per alimentazione
- Relè, con connessione ad apposito morsetto
- Sensore di temperatura

![Rotilio Maker Explained](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/RotilioThermoPictures.001.png)

## Requisiti necessari

Per iniziare occorre dotarsi di alcuni strumenti, se state leggendo questo tutorial su un computer desktop, PC o MAC che sia, siete già a buon punto. Il vostro computer, se dotato di connessione Internet, è pronto per inziare il lavoro.

Poi vi occorre un Rotilio Maker con un Photon, oppure un kit completo di tutto: Rotilio Maker, Photon, Scatola con flangia da parete e alimentatore per realizzare questo progetto.

Potete procurarvi i componenti singolarmente, se invece preferite abbreviare i tempi, ottimizzare i costi di spedizione e concentrarvi più sul software e le finezze, con il nostro kit siete a posto.

Dove procurarsi i componenti singoli:

### Rotilio Maker

![Rotilio Maker](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/RotilioMaker150.png)

Presso il nostro shop online: [http://techmakers.io/rotilio-maker.html](http://techmakers.io/rotilio-maker.html)

### Particle.io Photon

![Particle.io Photon](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/Photon.jpg)

Presso lo shop online di particle: [https://store.particle.io/collections/photon](https://store.particle.io/collections/photon)

### Rotilio Maker Kit
![Rotilio Maker Kit](https://raw.githubusercontent.com/techmakers/rotiliothermo/master/images/RotilioMakerKit.png)

Presso il notro shop online: [http://techmakers.io/rotilio-maker-kit.html](http://techmakers.io/rotilio-maker-kit.html)

[< Indice](README.md) | [Il firmware >](step-02-firmware.md)
 

