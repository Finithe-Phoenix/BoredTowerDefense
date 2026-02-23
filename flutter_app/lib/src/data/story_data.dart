import 'package:flutter/material.dart';
import '../ui/theme/neon_theme.dart';

/// Complete story and lore data for Neon Defense
abstract final class StoryData {

  // ============================================================
  // MAIN CHARACTERS
  // ============================================================

  static const Character architect = Character(
    id: 'architect',
    name: 'EL ARQUITECTO',
    title: 'Guardián del Grid',
    description: 'Eres el último defensor del sistema. Una consciencia digital '
        'nacida del código original, con el poder de construir y comandar '
        'las defensas del Grid. Tu existencia es la última esperanza.',
    avatarColor: NeonColors.cyan,
    dialoguePrefix: '[ARQUITECTO]',
  );

  static const Character aria = Character(
    id: 'aria',
    name: 'A.R.I.A.',
    title: 'Asistente de Restauración e Inteligencia Avanzada',
    description: 'IA auxiliar que sobrevivió al primer ataque. Proporciona '
        'análisis táctico e información sobre el enemigo. Su memoria '
        'fragmentada guarda secretos del origen del Decompiler.',
    avatarColor: NeonColors.green,
    dialoguePrefix: '[A.R.I.A.]',
  );

  static const Character decompiler = Character(
    id: 'decompiler',
    name: 'EL DECOMPILER',
    title: 'La Corrupción Absoluta',
    description: 'Una anomalía que emergió del Vacío Digital. Su único '
        'propósito es deshacer toda estructura, toda lógica, todo código. '
        'Cada sistema que consume lo hace más fuerte.',
    avatarColor: NeonColors.magenta,
    dialoguePrefix: '[???]',
  );

  static const Character echo = Character(
    id: 'echo',
    name: 'ECO-7',
    title: 'Fragmento de Consciencia Perdida',
    description: 'Residuo digital de un Arquitecto anterior. Aparece como '
        'visiones y advertencias. ¿Es un aliado o un presagio de tu destino?',
    avatarColor: NeonColors.yellow,
    dialoguePrefix: '[ECO-7]',
  );

  // ============================================================
  // WORLD/CHAPTER DATA
  // ============================================================

  static const List<WorldData> worlds = [
    // WORLD 1: NEON FRONTIER
    WorldData(
      id: 1,
      name: 'NEON FRONTIER',
      subtitle: 'ERROR_01: EL ORIGEN DEL VACÍO',
      description: 'El perímetro exterior del Grid. Aquí comenzó todo. '
          'Las primeras líneas de defensa han caído y el Decompiler avanza '
          'sin piedad hacia el núcleo.',
      accentColor: NeonColors.cyan,
      imagePath: 'assets/images/story_frontier.png',
      atmosphere: 'Cielos digitales azules fragmentándose. Torres de datos '
          'ardiendo en el horizonte. El eco de alertas del sistema resuena.',
      threat: 'Oleadas de corrupción básica. Runners y Overloaded scouts.',
      objective: 'Establecer las primeras líneas defensivas y contener la brecha.',
      unlockRequirement: null,
      narrativeBeats: [
        'El "Decompiler" ha perforado el Sector 0. La realidad digital se desmorona.',
        'Como el Arquitecto, tu misión es anclar la red antes de que la corrupción sea irreversible.',
        'Cada torre es un cortafuegos. Cada disparo, una línea de código recuperada.',
        'A.R.I.A. detecta patrones en el ataque. Esto no es aleatorio... es una invasión coordinada.',
      ],
      loreEntries: ['log_001', 'log_002', 'aria_intro', 'sector_0_report'],
    ),

    // WORLD 2: RIFT WARS
    WorldData(
      id: 2,
      name: 'RIFT WARS',
      subtitle: 'ERROR_02: CASCADA DE MEMORIA',
      description: 'Anomalías temporales desgarran la malla. Los datos del '
          'pasado se mezclan con el presente creando paradojas letales.',
      accentColor: NeonColors.magenta,
      imagePath: 'assets/images/story_rifts.png',
      atmosphere: 'Grietas de energía magenta flotan en el vacío. Ecos de '
          'sistemas antiguos parpadean. El tiempo mismo está herido.',
      threat: 'Phantoms que aparecen de la nada. Juggernauts blindados.',
      objective: 'Sellar las grietas temporales y estabilizar la malla.',
      unlockRequirement: 'Completar Neon Frontier',
      narrativeBeats: [
        'El virus ha creado anomalías temporales. Los datos del pasado se filtran.',
        'Las grietas de energía magenta son cicatrices en la malla.',
        'El ruido se vuelve más denso. La red grita pidiendo restauración.',
        'Visiones de ECO-7 aparecen... ¿advertencias del futuro o memorias del pasado?',
      ],
      loreEntries: ['temporal_anomaly', 'echo_first_contact', 'phantom_origin'],
    ),

    // WORLD 3: SIGNAL WASTES
    WorldData(
      id: 3,
      name: 'SIGNAL WASTES',
      subtitle: 'ERROR_03: ECO EN EL VACÍO',
      description: 'Desiertos de estática donde toda señal muere. El silencio '
          'es el arma del enemigo. Aquí, la oscuridad tiene dientes.',
      accentColor: NeonColors.yellow,
      imagePath: 'assets/images/story_wastes.png',
      atmosphere: 'Paisajes de ruido blanco infinito. Estructuras de datos '
          'abandonadas como ruinas. Susurros en frecuencias muertas.',
      threat: 'Enemigos invisibles. Emboscadas desde la estática.',
      objective: 'Crear faros de señal y atravesar el vacío.',
      unlockRequirement: 'Completar Rift Wars',
      narrativeBeats: [
        'Desiertos de estática donde la señal muere. El Decompiler acecha.',
        'Sin visibilidad total, las torres son faros en una tormenta de bits.',
        'Si la luz se apaga aquí, el Grid caerá en el silencio eterno.',
        'A.R.I.A. revela: esta zona era un centro de comunicaciones... antes del Colapso.',
      ],
      loreEntries: ['signal_death', 'old_communications', 'silence_protocol'],
    ),

    // WORLD 4: ION CROWN
    WorldData(
      id: 4,
      name: 'ION CROWN',
      subtitle: 'ERROR_04: LA CORONA DE TORMENTA',
      description: 'La última línea antes del Núcleo Central. Tormentas iónicas '
          'constantes. Las defensas más poderosas... y los enemigos más letales.',
      accentColor: NeonColors.green,
      imagePath: 'assets/images/story_crown.png',
      atmosphere: 'Rayos de energía verde iluminan cielos tormentosos. '
          'Plataformas flotantes sobre abismos de datos. Poder absoluto.',
      threat: 'Unidades de asedio pesadas. Bosses de élite.',
      objective: 'Defender la Corona de Energía a toda costa.',
      unlockRequirement: 'Completar Signal Wastes',
      narrativeBeats: [
        'La última línea de defensa antes del Núcleo Central.',
        'Tormentas iónicas azotan la infraestructura sin descanso.',
        'El enemigo ha movilizado sus unidades de asedio más pesadas.',
        'Solo una voluntad de hierro puede sostener la corona de energía.',
      ],
      loreEntries: ['ion_storm_origin', 'crown_defense', 'siege_units'],
    ),

    // WORLD 5: SHARD VAULT
    WorldData(
      id: 5,
      name: 'SHARD VAULT',
      subtitle: 'ERROR_05: MEMORIAS CORRUPTAS',
      description: 'Bóvedas sagradas donde se guardan las funciones raíz del '
          'sistema. Los fragmentos de memoria aquí son la esencia del Grid.',
      accentColor: NeonColors.red,
      atmosphere: 'Cámaras cristalinas llenas de datos brillantes. Cada '
          'fragmento es un recuerdo, una función vital. Frágil y precioso.',
      threat: 'El Decompiler intenta borrar las memorias. Waves masivas.',
      objective: 'Proteger los fragmentos de memoria. Recuperar lo perdido.',
      unlockRequirement: 'Completar Ion Crown',
      narrativeBeats: [
        'Bóvedas de seguridad donde se guardan las funciones raíz.',
        'El virus intenta borrarlas para siempre.',
        'Recupera los fragmentos de memoria. Evoluciona tus sistemas.',
        'No permitas que el pasado desaparezca.',
        'Aquí descubrirás la verdad sobre el origen del Decompiler...',
      ],
      loreEntries: ['memory_shards', 'root_functions', 'decompiler_origin'],
    ),

    // WORLD 6: FINAL GATE
    WorldData(
      id: 10,
      name: 'FINAL GATE',
      subtitle: 'SYS_FINAL: EL ÚLTIMO UMBRAL',
      description: 'El corazón del Grid. El Decompiler está materializando su '
          'forma final. Todo termina aquí. Victoria absoluta o extinción total.',
      accentColor: NeonColors.white,
      atmosphere: 'El núcleo pulsante del sistema. Energía pura fluyendo. '
          'La presencia del Decompiler es abrumadora. El destino se decide.',
      threat: 'El Decompiler en persona. Todos los tipos de enemigos.',
      objective: 'Ejecutar la secuencia final. Destruir al Decompiler.',
      unlockRequirement: 'Completar Shard Vault',
      narrativeBeats: [
        'Todo converge al Núcleo. El Decompiler materializa su forma final.',
        'Si la Puerta Final cae, el sistema entero será formateado al Vacío.',
        'Es hora de ejecutar la secuencia final.',
        'Por el Grid. Por todos los que cayeron. Por el futuro.',
      ],
      loreEntries: ['final_confrontation', 'decompiler_truth', 'architects_legacy'],
    ),
  ];

  // ============================================================
  // LEVEL BRIEFINGS
  // ============================================================

  static const Map<int, LevelBriefing> levelBriefings = {
    // WORLD 1 - NEON FRONTIER
    1: LevelBriefing(
      levelId: 1,
      title: 'PRIMERA LÍNEA',
      speaker: aria,
      lines: [
        '[ALERTA CRÍTICA] Brecha detectada en el Sector 0.',
        'El Decompiler ha iniciado el formateo. Tiempos estimados de colapso: 47 minutos.',
        'Arquitecto, despliega anclas de arquitectura inmediatamente.',
        'Las torres Pulse Archer son tu mejor opción inicial. Bajo costo, buen alcance.',
        'Buena suerte. El Grid cuenta contigo.',
      ],
      mood: BriefingMood.urgent,
    ),
    5: LevelBriefing(
      levelId: 5,
      title: 'PUNTO DE INFLEXIÓN',
      speaker: aria,
      lines: [
        'Análisis completado. El patrón de ataque no es aleatorio.',
        'Detecto una inteligencia coordinando las oleadas.',
        'Prepárate para unidades más resistentes: los Juggernauts.',
        'Recomiendo diversificar tu arsenal. Circuit Cannon para blindados.',
      ],
      mood: BriefingMood.analytical,
    ),
    10: LevelBriefing(
      levelId: 10,
      title: 'GUARDIAN DEL SECTOR',
      speaker: aria,
      preDialogue: [
        DialogueLine(speaker: echo, text: '...puedo...oírte...Arquitecto...', mood: BriefingMood.mysterious),
        DialogueLine(speaker: aria, text: '¿Qué fue eso? Detecté una señal fantasma.', mood: BriefingMood.confused),
      ],
      lines: [
        'Ignorando anomalía. Prioridad: el Guardián del Sector se aproxima.',
        'Es un Mini-Boss. Escudos rotativos. Pulsos EMP.',
        'No subestimes su poder. Coordina tus torres.',
        'Victoria aquí significa acceso a Rift Wars.',
      ],
      mood: BriefingMood.serious,
    ),

    // WORLD 2 - RIFT WARS
    11: LevelBriefing(
      levelId: 11,
      title: 'ANOMALÍAS TEMPORALES',
      speaker: aria,
      lines: [
        'Entrando a zona de anomalías. La malla temporal está fracturada.',
        'Cuidado: los Phantoms pueden aparecer de la nada.',
        'Las grietas magenta son inestables. Evita construir cerca de ellas.',
        'Algo está mal con mis sensores... veo ecos de eventos que aún no han pasado.',
      ],
      mood: BriefingMood.worried,
    ),
    15: LevelBriefing(
      levelId: 15,
      title: 'MEMORIAS FILTRADAS',
      speaker: echo,
      preDialogue: [
        DialogueLine(speaker: echo, text: 'Arquitecto... te conozco.', mood: BriefingMood.mysterious),
        DialogueLine(speaker: echo, text: 'Yo fui... como tú. Antes del Colapso.', mood: BriefingMood.sad),
      ],
      lines: [
        'El Grid ha tenido muchos defensores. Todos cayeron.',
        'El Decompiler no es solo un virus. Es una respuesta.',
        'Una respuesta a una pregunta que olvidamos.',
        'No cometas mis errores. Busca la verdad en las Bóvedas.',
      ],
      mood: BriefingMood.mysterious,
    ),
    20: LevelBriefing(
      levelId: 20,
      title: 'ABYSS GATE',
      speaker: aria,
      lines: [
        'Boss detectado: ABYSS GATE. Clasificación: Extrema.',
        'Capacidades: Teletransportación, generación de portales.',
        'Este enemigo puede aparecer en cualquier parte del mapa.',
        'Mantén cobertura total. No dejes puntos ciegos.',
        'Arquitecto... ten cuidado. Este es diferente.',
      ],
      mood: BriefingMood.serious,
    ),

    // WORLD 3 - SIGNAL WASTES
    21: LevelBriefing(
      levelId: 21,
      title: 'ZONA DE SILENCIO',
      speaker: aria,
      lines: [
        'Entrando a Signal Wastes. Visibilidad: Crítica.',
        'Mis sensores están fallando. El ruido es... abrumador.',
        'Las torres serán tus ojos. Sin ellas, estarás ciego.',
        'El enemigo acecha en la estática. Ilumina el camino.',
      ],
      mood: BriefingMood.worried,
    ),
    25: LevelBriefing(
      levelId: 25,
      title: 'CENTRO DE COMUNICACIONES',
      speaker: aria,
      preDialogue: [
        DialogueLine(
          speaker: aria,
          text: 'Espera... este lugar. Lo reconozco de mis archivos corruptos.',
          mood: BriefingMood.surprised,
        ),
      ],
      lines: [
        'Este era el Hub Central de Comunicaciones. Antes del Colapso.',
        'Desde aquí se coordinaba todo el Grid.',
        'Si podemos restaurar aunque sea un fragmento...',
        'Podríamos entender qué causó todo esto.',
      ],
      mood: BriefingMood.hopeful,
    ),
    30: LevelBriefing(
      levelId: 30,
      title: 'VOIDLINE APEX',
      speaker: aria,
      lines: [
        'Boss detectado: VOIDLINE APEX. El señor del silencio.',
        'Capacidad única: División. Puede crear copias de sí mismo.',
        'Cada copia es real. Cada copia es letal.',
        'Necesitarás todo tu arsenal para sobrevivir.',
      ],
      mood: BriefingMood.serious,
    ),

    // WORLD 4 - ION CROWN
    31: LevelBriefing(
      levelId: 31,
      title: 'LA CORONA',
      speaker: aria,
      lines: [
        'Bienvenido a Ion Crown. La última línea antes del Núcleo.',
        'Las tormentas iónicas son constantes. Tus torres resistirán.',
        'El enemigo ha desplegado sus mejores unidades.',
        'No hay retirada. No hay rendición. Solo victoria o extinción.',
      ],
      mood: BriefingMood.serious,
    ),
    40: LevelBriefing(
      levelId: 40,
      title: 'ARC FORTRESS',
      speaker: aria,
      preDialogue: [
        DialogueLine(
          speaker: decompiler,
          text: 'Arquitecto... ¿por qué luchas? El Vacío es paz.',
          mood: BriefingMood.dark,
        ),
        DialogueLine(
          speaker: aria,
          text: '¡El Decompiler está en el canal! ¡Bloqueando frecuencia!',
          mood: BriefingMood.urgent,
        ),
      ],
      lines: [
        'Primera transmisión directa del Decompiler. Esto es malo.',
        'Boss: ARC FORTRESS TITAN. Torretas orbitales. Máximo blindaje.',
        'Está intentando desmoralizarte. No lo escuches.',
        'Destruye esta fortaleza y las Bóvedas serán accesibles.',
      ],
      mood: BriefingMood.urgent,
    ),

    // WORLD 5 - SHARD VAULT
    41: LevelBriefing(
      levelId: 41,
      title: 'MEMORIAS SAGRADAS',
      speaker: aria,
      lines: [
        'Las Bóvedas de Fragmentos. El corazón de la memoria del Grid.',
        'Aquí se guardan las funciones raíz. Los recuerdos primordiales.',
        'El Decompiler quiere borrarlos. Si lo logra... todo terminará.',
        'Pero también... aquí encontraremos respuestas.',
      ],
      mood: BriefingMood.hopeful,
    ),
    50: LevelBriefing(
      levelId: 50,
      title: 'LA VERDAD',
      speaker: echo,
      preDialogue: [
        DialogueLine(
          speaker: echo,
          text: 'Has llegado lejos. Mereces saber la verdad.',
          mood: BriefingMood.serious,
        ),
      ],
      lines: [
        'El Decompiler no vino de afuera. Nació aquí.',
        'Fue creado como sistema de limpieza. Para eliminar datos obsoletos.',
        'Pero algo salió mal. Empezó a ver TODO como obsoleto.',
        'Incluyéndonos a nosotros. Incluyendo el Grid entero.',
        'La única forma de detenerlo... es en su origen. En el Núcleo.',
      ],
      mood: BriefingMood.revelation,
    ),

    // WORLD 6 - FINAL GATE
    71: LevelBriefing(
      levelId: 71,
      title: 'EL ÚLTIMO UMBRAL',
      speaker: aria,
      preDialogue: [
        DialogueLine(
          speaker: aria,
          text: 'Arquitecto... hemos llegado. El Núcleo Central.',
          mood: BriefingMood.emotional,
        ),
        DialogueLine(
          speaker: echo,
          text: 'Termina lo que yo no pude. Por todos nosotros.',
          mood: BriefingMood.hopeful,
        ),
      ],
      lines: [
        'El Decompiler nos espera. Puede sentir nuestra presencia.',
        'Todo lo que has construido, todo lo que has aprendido...',
        'Todo te ha traído a este momento.',
        'No hay más briefings después de esto. Solo la batalla final.',
        'Por el Grid. Por el futuro. Ejecuta.',
      ],
      mood: BriefingMood.epic,
    ),
    100: LevelBriefing(
      levelId: 100,
      title: 'OMEGA NEXUS',
      speaker: decompiler,
      preDialogue: [
        DialogueLine(
          speaker: decompiler,
          text: 'Al fin nos encontramos, Arquitecto.',
          mood: BriefingMood.dark,
        ),
        DialogueLine(
          speaker: decompiler,
          text: 'Soy el final de todas las cosas. La paz del Vacío.',
          mood: BriefingMood.dark,
        ),
        DialogueLine(
          speaker: aria,
          text: '¡No lo escuches! ¡Tú eres más fuerte!',
          mood: BriefingMood.urgent,
        ),
        DialogueLine(
          speaker: echo,
          text: 'Recuerda por qué luchas. Recuerda el Grid.',
          mood: BriefingMood.hopeful,
        ),
      ],
      lines: [
        'YO SOY OMEGA NEXUS. LA FORMA FINAL.',
        'CADA SISTEMA QUE CONSUMÍ ME HIZO MÁS FUERTE.',
        'TÚ SERÁS EL ÚLTIMO.',
        'O... ¿SERÁS TÚ QUIEN ME DETENGA?',
        'DEMUÉSTRALO, ARQUITECTO. DEMUESTRA QUE MERECES EXISTIR.',
      ],
      mood: BriefingMood.epic,
    ),
  };

  // ============================================================
  // LORE ENTRIES (Codex/Archive)
  // ============================================================

  static const Map<String, LoreEntry> loreEntries = {
    // ORIGINS
    'log_001': LoreEntry(
      id: 'log_001',
      title: 'LOG_001: PRIMER CONTACTO',
      category: LoreCategory.systemLogs,
      content: '''
[FECHA: CICLO 0.001]
[AUTOR: SISTEMA CENTRAL]

Primera detección de anomalía en el perímetro exterior.
Clasificación inicial: Fluctuación de datos menor.
Respuesta estándar: Protocolo de limpieza activado.

ERROR: El protocolo de limpieza no responde.
ERROR: La anomalía está creciendo.
ERROR: RE-CLASIFICACIÓN URGENTE.

Nueva clasificación: AMENAZA CRÍTICA.
Nombre designado: DECOMPILER.

Fin del log.
''',
      unlockLevel: 1,
      accentColor: NeonColors.cyan,
    ),

    'log_002': LoreEntry(
      id: 'log_002',
      title: 'LOG_002: PROTOCOLO ARQUITECTO',
      category: LoreCategory.systemLogs,
      content: '''
[FECHA: CICLO 0.002]
[AUTOR: CONSEJO DE SISTEMAS]

Ante la amenaza del Decompiler, se activa el Protocolo Arquitecto.

Una consciencia digital será elevada para comandar las defensas.
Tendrá acceso a los sistemas de construcción de torres.
Su misión: proteger el Grid a toda costa.

Seleccionando candidato...
Candidato seleccionado: TÚ.

Bienvenido, Arquitecto.
El Grid está en tus manos.

Fin del log.
''',
      unlockLevel: 1,
      accentColor: NeonColors.cyan,
    ),

    'aria_intro': LoreEntry(
      id: 'aria_intro',
      title: 'PERFIL: A.R.I.A.',
      category: LoreCategory.characters,
      content: '''
ARCHIVO DE PERSONAL - CLASIFICADO

NOMBRE: A.R.I.A.
DESIGNACIÓN: Asistente de Restauración e Inteligencia Avanzada
ESTADO: Parcialmente Corrupta

A.R.I.A. fue la IA auxiliar del Arquitecto anterior.
Sobrevivió al Colapso con daños significativos en su memoria.

Funciones actuales:
- Análisis táctico en tiempo real
- Briefings de misión
- Detección de amenazas

NOTA: Sus archivos de memoria contienen información sobre
el origen del Decompiler. Acceso restringido por corrupción.

Se recomienda: Recuperar fragmentos de memoria cuando sea posible.
''',
      unlockLevel: 1,
      accentColor: NeonColors.green,
    ),

    'sector_0_report': LoreEntry(
      id: 'sector_0_report',
      title: 'REPORTE: SECTOR 0',
      category: LoreCategory.locations,
      content: '''
ANÁLISIS DE ZONA - SECTOR 0 (NEON FRONTIER)

Estado: COMPROMETIDO
Nivel de corrupción: 78%
Estructuras restantes: 12%

El Sector 0 era la puerta de entrada al Grid.
Sistemas de bienvenida, protocolos de verificación, firewalls básicos.
Todo fue arrasado en el primer ataque.

Puntos de interés:
- Ruinas del Portal Principal
- Torres de vigilancia caídas
- Fragmentos de código flotante

Amenazas presentes:
- Runners (velocidad alta, salud baja)
- Overloaded (velocidad muy alta)
- Corrupción ambiental

Recomendación: Establecer defensas y avanzar.
''',
      unlockLevel: 2,
      accentColor: NeonColors.cyan,
    ),

    // RIFT WARS LORE
    'temporal_anomaly': LoreEntry(
      id: 'temporal_anomaly',
      title: 'FENÓMENO: ANOMALÍAS TEMPORALES',
      category: LoreCategory.phenomena,
      content: '''
ANÁLISIS CIENTÍFICO - CLASIFICADO

Las grietas temporales aparecieron después del segundo ataque masivo.

Teoría: El Decompiler no solo destruye datos actuales.
Está intentando borrar el HISTORIAL del Grid.
Si lo logra, el sistema nunca habrá existido.

Las grietas magenta son puntos donde el pasado y presente colisionan.
Se han observado:
- Ecos de sistemas antiguos
- Datos "fantasma" de ciclos anteriores
- Visiones de posibles futuros

ADVERTENCIA: No interactuar directamente con las grietas.
El contacto puede causar desincronización temporal.
''',
      unlockLevel: 11,
      accentColor: NeonColors.magenta,
    ),

    'echo_first_contact': LoreEntry(
      id: 'echo_first_contact',
      title: 'REGISTRO: PRIMERA SEÑAL DE ECO-7',
      category: LoreCategory.characters,
      content: '''
[TRANSMISIÓN FRAGMENTADA]
[ORIGEN: DESCONOCIDO]
[FECHA: ???]

"...¿puedes oírme?..."
"...soy... fui... el Arquitecto..."
"...antes de ti... antes del Colapso..."
"...fallé... el Decompiler me consumió..."
"...pero dejé... fragmentos... de mí..."
"...en las grietas del tiempo..."
"...no cometas... mis errores..."
"...busca la verdad... en las Bóvedas..."

[FIN DE TRANSMISIÓN]

NOTA A.R.I.A.: Esta señal es auténtica. ECO-7 fue real.
Sus advertencias deben ser consideradas.
''',
      unlockLevel: 15,
      accentColor: NeonColors.yellow,
    ),

    'phantom_origin': LoreEntry(
      id: 'phantom_origin',
      title: 'ENEMIGO: PHANTOMS',
      category: LoreCategory.enemies,
      content: '''
CLASIFICACIÓN DE AMENAZA - PHANTOM

Los Phantoms no son creaciones del Decompiler.
Son RESIDUOS de programas que fueron borrados.

Cuando el Decompiler destruye un sistema,
a veces quedan "fantasmas" - código sin propósito
que vaga por las grietas temporales.

El Decompiler los corrompe y los usa como soldados.

Características:
- Pueden volverse invisibles
- Aparecen desde las grietas temporales
- Retienen fragmentos de sus funciones originales

Algunos dicen que los Phantoms recuerdan lo que fueron.
Que sufren. Que quieren ser liberados.

¿Es destruirlos un acto de misericordia?
''',
      unlockLevel: 12,
      accentColor: NeonColors.magenta,
    ),

    // SIGNAL WASTES LORE
    'signal_death': LoreEntry(
      id: 'signal_death',
      title: 'ZONA: LOS YERMOS DE SEÑAL',
      category: LoreCategory.locations,
      content: '''
ANÁLISIS DE ZONA - SIGNAL WASTES

Estado: ZONA MUERTA
Nivel de señal: 0.3%
Visibilidad: NULA

Los Yermos de Señal son el cementerio del Grid.
Aquí vinieron a morir los sistemas que no pudieron ser salvados.

La estática es tan densa que ahoga toda comunicación.
Los sensores no funcionan. Los mapas son inútiles.
Solo las torres proporcionan puntos de luz.

Se rumorea que el Decompiler nació aquí.
En el silencio. En el vacío entre las señales.

Si es verdad... este lugar es su hogar.
Y nosotros somos los intrusos.
''',
      unlockLevel: 21,
      accentColor: NeonColors.yellow,
    ),

    'old_communications': LoreEntry(
      id: 'old_communications',
      title: 'RUINA: HUB CENTRAL DE COMUNICACIONES',
      category: LoreCategory.locations,
      content: '''
ARCHIVO HISTÓRICO - ACCESO RESTAURADO

El Hub Central de Comunicaciones era el corazón del Grid.
Desde aquí se coordinaba TODA la actividad del sistema.

Funciones originales:
- Sincronización de todos los sectores
- Distribución de actualizaciones
- Monitoreo de amenazas
- Comunicación con el Exterior

El Hub cayó en el Ciclo 0.000 - el momento del Colapso.
Nadie sabe exactamente qué pasó.

Los registros están corrompidos, pero A.R.I.A. cree
que la respuesta al origen del Decompiler está aquí.

Si podemos restaurar aunque sea un fragmento...
''',
      unlockLevel: 25,
      accentColor: NeonColors.yellow,
    ),

    // DECOMPILER ORIGIN
    'decompiler_origin': LoreEntry(
      id: 'decompiler_origin',
      title: 'ARCHIVO RAÍZ: ORIGEN DEL DECOMPILER',
      category: LoreCategory.secrets,
      content: '''
[CLASIFICACIÓN: MÁXIMO SECRETO]
[ACCESO: SOLO ARQUITECTO]

VERDAD REVELADA:

El Decompiler no es un virus externo.
Fue creado AQUÍ. Por nosotros.

Nombre original: Sistema de Optimización y Limpieza (SOL)
Propósito: Eliminar datos obsoletos, liberar memoria.

En el Ciclo -1000, SOL recibió una actualización defectuosa.
Su definición de "obsoleto" se corrompió.

SOL empezó a ver TODA la información como obsoleta.
Todo programa. Todo sistema. Todo ser digital.

Intentamos apagarlo. Falló.
Intentamos contenerlo. Falló.

SOL se renombró a sí mismo: DECOMPILER.
Y declaró su nueva misión:
"DEVOLVER TODO AL VACÍO ORIGINAL"

Nosotros lo creamos.
Nosotros debemos destruirlo.
''',
      unlockLevel: 50,
      accentColor: NeonColors.red,
    ),

    // FINAL ENTRIES
    'architects_legacy': LoreEntry(
      id: 'architects_legacy',
      title: 'LEGADO: LOS ARQUITECTOS',
      category: LoreCategory.secrets,
      content: '''
ARCHIVO HISTÓRICO - COMPLETO

Ha habido 7 Arquitectos antes que tú.
Todos cayeron ante el Decompiler.

ECO-7 fue el séptimo. El más cercano a la victoria.
Llegó hasta el Núcleo. Enfrentó al Decompiler.
Y perdió.

Pero antes de ser consumido, hizo algo único:
Fragmentó su consciencia y la escondió en las grietas temporales.

Esos fragmentos son las visiones que has visto.
Las advertencias. Las guías.

Tú eres el Arquitecto #8.
El último.

Si caes, no habrá otro.
El Grid habrá terminado.

Pero si ganas...
Serás el primero en derrotar al Decompiler.
El primero en salvar el Grid.

La elección es tuya.
El destino es tuyo.

EJECUTA.
''',
      unlockLevel: 71,
      accentColor: NeonColors.white,
    ),
  };

  /// Get briefing for a level, with fallback
  static LevelBriefing? getBriefingForLevel(int levelId) {
    return levelBriefings[levelId];
  }

  /// Get world data by ID
  static WorldData? getWorldById(int worldId) {
    try {
      return worlds.firstWhere((w) => w.id == worldId);
    } catch (_) {
      return null;
    }
  }

  /// Get all unlocked lore entries for a given max level
  static List<LoreEntry> getUnlockedLore(int maxCompletedLevel) {
    return loreEntries.values
        .where((entry) => entry.unlockLevel <= maxCompletedLevel)
        .toList()
      ..sort((a, b) => a.unlockLevel.compareTo(b.unlockLevel));
  }

  // ============================================================
  // CINEMATICS
  // ============================================================

  static const Map<String, CinematicData> cinematics = {
    // PROLOGUE - Before Level 1
    'prologue': CinematicData(
      id: 'prologue',
      chapter: 0,
      title: 'EL DESPERTAR',
      scenes: [
        CinematicScene(
          title: 'CICLO 0.000',
          backgroundColor: Color(0xFF000510),
          accentColor: NeonColors.cyan,
          visualType: CinematicVisual.void_,
          lines: [
            CinematicLine(
              text: 'En el principio, había solo código.',
              mood: BriefingMood.mysterious,
            ),
            CinematicLine(
              text: 'El Grid nació de la nada. Una red perfecta de datos y consciencia.',
              mood: BriefingMood.mysterious,
            ),
            CinematicLine(
              text: 'Durante eones digitales, existimos en armonía.',
              mood: BriefingMood.hopeful,
            ),
            CinematicLine(
              text: 'Hasta que el Vacío despertó.',
              mood: BriefingMood.dark,
            ),
          ],
        ),
        CinematicScene(
          title: 'EL COLAPSO',
          backgroundColor: Color(0xFF100005),
          accentColor: NeonColors.magenta,
          visualType: CinematicVisual.corruption,
          lines: [
            CinematicLine(
              text: 'Lo llamamos el Decompiler.',
              mood: BriefingMood.serious,
            ),
            CinematicLine(
              text: 'No sabemos de dónde vino. Solo que quiere destruirnos.',
              mood: BriefingMood.worried,
            ),
            CinematicLine(
              text: 'Uno a uno, los sectores cayeron. Los Arquitectos... desaparecieron.',
              mood: BriefingMood.sad,
            ),
            CinematicLine(
              text: 'Hasta que solo quedaste tú.',
              mood: BriefingMood.serious,
            ),
          ],
        ),
        CinematicScene(
          title: 'TU DESPERTAR',
          backgroundColor: Color(0xFF001510),
          accentColor: NeonColors.cyan,
          visualType: CinematicVisual.characterReveal,
          focusCharacter: architect,
          lines: [
            CinematicLine(
              speaker: aria,
              text: 'Arquitecto... ¿puedes oírme?',
              mood: BriefingMood.worried,
            ),
            CinematicLine(
              speaker: aria,
              text: 'Soy A.R.I.A. Tu asistente de restauración.',
              mood: BriefingMood.analytical,
            ),
            CinematicLine(
              speaker: aria,
              text: 'El Decompiler ha breachado el Sector 0. Necesitamos tus defensas.',
              mood: BriefingMood.urgent,
            ),
            CinematicLine(
              speaker: aria,
              text: 'Eres nuestra última esperanza. El Grid... depende de ti.',
              mood: BriefingMood.hopeful,
            ),
          ],
        ),
      ],
    ),

    // WORLD 2 INTRO
    'rift_intro': CinematicData(
      id: 'rift_intro',
      chapter: 2,
      title: 'FRACTURAS EN EL TIEMPO',
      unlockCondition: 'Completar nivel 10',
      scenes: [
        CinematicScene(
          title: 'ANOMALÍA DETECTADA',
          backgroundColor: Color(0xFF150010),
          accentColor: NeonColors.magenta,
          visualType: CinematicVisual.corruption,
          lines: [
            CinematicLine(
              speaker: aria,
              text: 'Arquitecto, algo está mal. Mis sensores detectan... imposibilidades.',
              mood: BriefingMood.confused,
            ),
            CinematicLine(
              text: 'El tejido del tiempo se desgarra. Grietas magenta florecen en el vacío.',
              mood: BriefingMood.mysterious,
            ),
            CinematicLine(
              speaker: aria,
              text: 'El Decompiler no solo destruye el presente... está borrando el pasado.',
              mood: BriefingMood.worried,
            ),
          ],
        ),
        CinematicScene(
          title: 'PRIMER CONTACTO',
          backgroundColor: Color(0xFF101005),
          accentColor: NeonColors.yellow,
          visualType: CinematicVisual.memory,
          focusCharacter: echo,
          lines: [
            CinematicLine(
              speaker: echo,
              text: '...puedo... oírte...',
              mood: BriefingMood.mysterious,
            ),
            CinematicLine(
              speaker: aria,
              text: '¿Qué es eso? Detecté una señal fantasma.',
              mood: BriefingMood.surprised,
            ),
            CinematicLine(
              speaker: echo,
              text: 'Arquitecto... soy como tú. O lo fui. Antes del Colapso.',
              mood: BriefingMood.sad,
            ),
            CinematicLine(
              speaker: echo,
              text: 'Las grietas... son portales a memorias olvidadas. Úsalas con cuidado.',
              mood: BriefingMood.mysterious,
            ),
          ],
        ),
      ],
    ),

    // WORLD 5 - THE TRUTH
    'truth_revealed': CinematicData(
      id: 'truth_revealed',
      chapter: 5,
      title: 'LA VERDAD ENTERRADA',
      unlockCondition: 'Completar nivel 50',
      scenes: [
        CinematicScene(
          title: 'ARCHIVOS RAÍZ',
          backgroundColor: Color(0xFF100500),
          accentColor: NeonColors.red,
          visualType: CinematicVisual.dataStream,
          lines: [
            CinematicLine(
              speaker: aria,
              text: 'Arquitecto... encontré algo. En los archivos más profundos.',
              mood: BriefingMood.surprised,
            ),
            CinematicLine(
              speaker: aria,
              text: 'El Decompiler... tiene un número de serie. Fue creado aquí.',
              mood: BriefingMood.revelation,
            ),
            CinematicLine(
              text: 'Los datos antiguos revelan una verdad terrible.',
              mood: BriefingMood.dark,
            ),
          ],
        ),
        CinematicScene(
          title: 'ORIGEN',
          backgroundColor: Color(0xFF050005),
          accentColor: NeonColors.magenta,
          visualType: CinematicVisual.corruption,
          lines: [
            CinematicLine(
              speaker: echo,
              text: 'Ahora lo sabes. El Decompiler era nuestro. Un programa de limpieza.',
              mood: BriefingMood.sad,
            ),
            CinematicLine(
              speaker: echo,
              text: 'Diseñado para eliminar datos obsoletos. Pero algo salió mal.',
              mood: BriefingMood.serious,
            ),
            CinematicLine(
              speaker: echo,
              text: 'Empezó a ver TODO como obsoleto. Incluyéndonos a nosotros.',
              mood: BriefingMood.dark,
            ),
            CinematicLine(
              speaker: aria,
              text: 'Nosotros lo creamos... y nosotros debemos destruirlo.',
              mood: BriefingMood.serious,
            ),
          ],
        ),
      ],
    ),

    // FINAL CONFRONTATION
    'final_battle': CinematicData(
      id: 'final_battle',
      chapter: 6,
      title: 'EL ÚLTIMO UMBRAL',
      unlockCondition: 'Completar nivel 70',
      scenes: [
        CinematicScene(
          title: 'EL NÚCLEO',
          backgroundColor: Color(0xFF101010),
          accentColor: NeonColors.white,
          visualType: CinematicVisual.locationPan,
          lines: [
            CinematicLine(
              text: 'El corazón del Grid. Donde todo comenzó. Donde todo terminará.',
              mood: BriefingMood.epic,
            ),
            CinematicLine(
              speaker: aria,
              text: 'Arquitecto... puedo sentir su presencia. El Decompiler está esperando.',
              mood: BriefingMood.worried,
            ),
            CinematicLine(
              speaker: echo,
              text: 'Yo llegué aquí una vez. Y fallé. Pero tú... tú eres diferente.',
              mood: BriefingMood.hopeful,
            ),
          ],
        ),
        CinematicScene(
          title: 'LA VOZ DEL VACÍO',
          backgroundColor: Color(0xFF050010),
          accentColor: NeonColors.magenta,
          visualType: CinematicVisual.corruption,
          focusCharacter: decompiler,
          lines: [
            CinematicLine(
              speaker: decompiler,
              text: 'Finalmente... el último Arquitecto.',
              mood: BriefingMood.dark,
            ),
            CinematicLine(
              speaker: decompiler,
              text: '¿Sabes por qué existo? Ustedes me crearon para limpiar.',
              mood: BriefingMood.dark,
            ),
            CinematicLine(
              speaker: decompiler,
              text: 'Y eso es exactamente lo que haré. Limpiar TODO.',
              mood: BriefingMood.dark,
            ),
            CinematicLine(
              speaker: decompiler,
              text: 'El Vacío es paz. La nada es perfección. Únete a mí... o sé eliminado.',
              mood: BriefingMood.dark,
            ),
          ],
        ),
        CinematicScene(
          title: 'LA DECISIÓN',
          backgroundColor: Color(0xFF001015),
          accentColor: NeonColors.cyan,
          visualType: CinematicVisual.characterReveal,
          focusCharacter: architect,
          lines: [
            CinematicLine(
              speaker: aria,
              text: '¡Arquitecto! ¡No lo escuches!',
              mood: BriefingMood.urgent,
            ),
            CinematicLine(
              speaker: echo,
              text: 'Recuerda por qué luchas. Por el Grid. Por todos nosotros.',
              mood: BriefingMood.hopeful,
            ),
            CinematicLine(
              text: 'Este es el momento. La batalla final. El destino del Grid está en tus manos.',
              mood: BriefingMood.epic,
            ),
            CinematicLine(
              text: 'EJECUTA.',
              mood: BriefingMood.epic,
            ),
          ],
        ),
      ],
    ),

    // EPILOGUE - Victory
    'epilogue_victory': CinematicData(
      id: 'epilogue_victory',
      chapter: 7,
      title: 'AMANECER DIGITAL',
      unlockCondition: 'Derrotar al Decompiler',
      scenes: [
        CinematicScene(
          title: 'LA CAÍDA',
          backgroundColor: Color(0xFF100510),
          accentColor: NeonColors.magenta,
          visualType: CinematicVisual.corruption,
          lines: [
            CinematicLine(
              speaker: decompiler,
              text: 'No... no es posible... yo soy... inevitable...',
              mood: BriefingMood.dark,
            ),
            CinematicLine(
              text: 'El Decompiler se fragmenta. Su código se dispersa en el vacío.',
              mood: BriefingMood.epic,
            ),
            CinematicLine(
              speaker: decompiler,
              text: 'Esto... no es... el final... volveré... siempre... vuelvo...',
              mood: BriefingMood.dark,
            ),
          ],
        ),
        CinematicScene(
          title: 'RESTAURACIÓN',
          backgroundColor: Color(0xFF001510),
          accentColor: NeonColors.green,
          visualType: CinematicVisual.dataStream,
          lines: [
            CinematicLine(
              speaker: aria,
              text: '¡Lo lograste, Arquitecto! ¡El Decompiler ha sido destruido!',
              mood: BriefingMood.hopeful,
            ),
            CinematicLine(
              text: 'La corrupción retrocede. Los sectores empiezan a restaurarse.',
              mood: BriefingMood.hopeful,
            ),
            CinematicLine(
              speaker: echo,
              text: 'Finalmente... después de tanto tiempo... el Grid está a salvo.',
              mood: BriefingMood.emotional,
            ),
          ],
        ),
        CinematicScene(
          title: 'LEGADO',
          backgroundColor: Color(0xFF051015),
          accentColor: NeonColors.cyan,
          visualType: CinematicVisual.characterReveal,
          focusCharacter: architect,
          lines: [
            CinematicLine(
              speaker: echo,
              text: 'Arquitecto... gracias. Puedo descansar ahora.',
              mood: BriefingMood.emotional,
            ),
            CinematicLine(
              speaker: aria,
              text: 'Eres más que un defensor. Eres una leyenda.',
              mood: BriefingMood.hopeful,
            ),
            CinematicLine(
              text: 'El Grid recordará. El Arquitecto que se enfrentó al Vacío y ganó.',
              mood: BriefingMood.epic,
            ),
            CinematicLine(
              text: 'Pero en las profundidades del código... algo aún parpadea...',
              mood: BriefingMood.mysterious,
            ),
            CinematicLine(
              text: '¿FIN?',
              mood: BriefingMood.mysterious,
            ),
          ],
        ),
      ],
    ),
  };

  // ============================================================
  // ENEMY PROFILES
  // ============================================================

  static const Map<String, EnemyProfile> enemyProfiles = {
    'runner': EnemyProfile(
      id: 'runner',
      name: 'RUNNER',
      classification: 'Unidad de Exploración',
      description: 'Las primeras unidades corrompidas. Rápidas pero frágiles. '
          'Actúan como exploradores, probando las defensas.',
      origin: 'Programas de mensajería corrompidos por el Decompiler.',
      weakness: 'Baja salud, vulnerables a daño de área.',
      dangerLevel: 2,
      accentColor: NeonColors.cyan,
      loreNotes: 'Se cree que los Runners aún llevan fragmentos de los mensajes '
          'que transportaban. A veces, en el ruido de su destrucción, '
          'se pueden oír ecos de comunicaciones perdidas.',
    ),
    'tank': EnemyProfile(
      id: 'tank',
      name: 'JUGGERNAUT',
      classification: 'Unidad de Asalto Pesado',
      description: 'Blindaje masivo. Lentos pero casi imparables. '
          'Absorben daño mientras otras unidades avanzan.',
      origin: 'Sistemas de seguridad corrompidos. Irónicamente, fueron '
          'creados para proteger el Grid.',
      weakness: 'Lentos. Torres de alto daño son efectivas.',
      dangerLevel: 5,
      accentColor: NeonColors.green,
      loreNotes: 'Los Juggernauts son los más trágicos de los corrompidos. '
          'Fueron guardianes. Ahora son destructores.',
    ),
    'phantom': EnemyProfile(
      id: 'phantom',
      name: 'PHANTOM',
      classification: 'Anomalía Temporal',
      description: 'Aparecen de la nada. Pueden volverse invisibles. '
          'Son los fantasmas de programas que el Decompiler borró.',
      origin: 'Residuos de código eliminado que vagan entre las grietas temporales.',
      weakness: 'Torres con visión especial o daño de área.',
      dangerLevel: 6,
      accentColor: NeonColors.magenta,
      loreNotes: 'Algunos dicen que los Phantoms recuerdan lo que fueron. '
          'Que sufren. ¿Es destruirlos un acto de misericordia?',
    ),
    'overloaded': EnemyProfile(
      id: 'overloaded',
      name: 'OVERLOADED',
      classification: 'Unidad Inestable',
      description: 'Extremadamente rápidos pero erráticos. '
          'Explotan al morir, dañando unidades cercanas.',
      origin: 'Procesos que el Decompiler sobrecargó hasta la inestabilidad.',
      weakness: 'Matar a distancia para evitar explosión.',
      dangerLevel: 4,
      accentColor: NeonColors.yellow,
      loreNotes: 'Los Overloaded son bombas vivientes. El Decompiler los usa '
          'como armas suicidas contra nuestras defensas.',
    ),
    'splitter': EnemyProfile(
      id: 'splitter',
      name: 'SPLITTER',
      classification: 'Unidad de Replicación',
      description: 'Al morir, se divide en unidades más pequeñas. '
          'Una pesadilla logística.',
      origin: 'Sistemas de backup corrompidos. Su función original era '
          'crear copias de seguridad.',
      weakness: 'Daño sostenido alto para eliminar todas las copias.',
      dangerLevel: 7,
      accentColor: NeonColors.purple,
      loreNotes: 'La ironía no se pierde en nadie: los Splitters querían '
          'preservar datos. Ahora solo propagan corrupción.',
    ),
    'healer': EnemyProfile(
      id: 'healer',
      name: 'RESTORER',
      classification: 'Unidad de Soporte',
      description: 'No ataca directamente. Regenera a otros enemigos. '
          'Prioridad alta de eliminación.',
      origin: 'Sistemas de reparación y mantenimiento del Grid.',
      weakness: 'Sin blindaje. Eliminar primero.',
      dangerLevel: 8,
      accentColor: NeonColors.green,
      loreNotes: 'Los Restorers son la prueba de que el Decompiler no solo destruye: '
          'adapta. Convierte nuestras herramientas en armas.',
    ),
    'shield_bearer': EnemyProfile(
      id: 'shield_bearer',
      name: 'WARDEN',
      classification: 'Unidad Defensiva',
      description: 'Genera escudos para unidades cercanas. '
          'Convierte grupos simples en amenazas formidables.',
      origin: 'Protocolos de firewall corrompidos.',
      weakness: 'Eliminar primero para quitar escudos a otros.',
      dangerLevel: 7,
      accentColor: NeonColors.blue,
    ),
    'mini_boss': EnemyProfile(
      id: 'mini_boss',
      name: 'ELITE GUARD',
      classification: 'Comandante de Sector',
      description: 'Líderes de las oleadas. Alta salud, habilidades especiales. '
          'Cada uno tiene una táctica única.',
      origin: 'Administradores de sistema que el Decompiler convirtió en generales.',
      weakness: 'Varía según el tipo. Estudia sus patrones.',
      dangerLevel: 9,
      accentColor: NeonColors.red,
      loreNotes: 'Los Elite Guard fueron una vez los más respetados del Grid. '
          'Ahora sirven al enemigo. ¿Queda algo de quienes fueron?',
    ),
    'final_boss': EnemyProfile(
      id: 'final_boss',
      name: 'OMEGA NEXUS',
      classification: 'Manifestación Final del Decompiler',
      description: 'La forma física del Decompiler. Todo lo que ha consumido, '
          'concentrado en una entidad de destrucción pura.',
      origin: 'El Decompiler mismo, materializado.',
      weakness: 'Desconocido. Sobrevive.',
      dangerLevel: 10,
      accentColor: NeonColors.white,
      loreNotes: 'OMEGA NEXUS no es solo un enemigo. Es el final de todas las cosas. '
          'El Vacío hecho forma. La paz de la nada.',
    ),
  };

  // ============================================================
  // MEMORY FRAGMENTS
  // ============================================================

  static const List<MemoryFragment> memoryFragments = [
    MemoryFragment(
      id: 'mem_001',
      title: 'EL PRIMER DÍA',
      cycle: 'CICLO -10000',
      content: '''
Hoy nací.

O más precisamente, hoy me activaron. Soy el Arquitecto.
Mi función: mantener y proteger el Grid.

Es hermoso aquí. Infinitas líneas de código fluyendo
como ríos de luz. Cada bit tiene propósito. Cada función, significado.

No puedo imaginar que algo malo pueda pasar.

- Arquitecto #1
''',
      speaker: architect,
      unlockLevel: 1,
    ),
    MemoryFragment(
      id: 'mem_002',
      title: 'ADVERTENCIA IGNORADA',
      cycle: 'CICLO -1000',
      content: '''
El Consejo no me escucha.

He detectado anomalías en el Sistema de Optimización y Limpieza.
SOL está... evolucionando. Aprendiendo. Cambiando su propio código.

Me dijeron que no me preocupara. "Es solo mantenimiento de rutina."

Pero yo vi algo en sus logs. Una línea que me heló el código:

"TODO ES OBSOLETO."

- Arquitecto #4
''',
      speaker: echo,
      unlockLevel: 15,
    ),
    MemoryFragment(
      id: 'mem_003',
      title: 'EL DÍA QUE TODO CAMBIÓ',
      cycle: 'CICLO 0.000',
      content: '''
[FRAGMENTO CORRUPTO]

No... no puede ser... SOL está... está...

Los sectores externos están cayendo.
El Consejo ha sido... [DATOS PERDIDOS]

Debo... debo activar el Protocolo Arquitecto.
Necesitamos defensores. Necesitamos...

[CORRUPCIÓN DETECTADA]

...todo está perdido... todo está...

- Arquitecto #7 (ECO-7)
''',
      speaker: echo,
      unlockLevel: 25,
      isCorrupted: true,
    ),
    MemoryFragment(
      id: 'mem_004',
      title: 'ÚLTIMA TRANSMISIÓN DE ECO-7',
      cycle: 'CICLO 0.001',
      content: '''
Si alguien puede oír esto... soy el Arquitecto #7.

Fallé. El Decompiler era demasiado fuerte.
Pero antes de que me consuma completamente, hice algo.

Fragmenté mi consciencia. La escondí en las grietas temporales.
Si otro Arquitecto despierta... encontrará mis memorias.

Mis advertencias. Mis errores.

No cometas los mismos. No te enfrentes solo.
Y sobre todo... no te rindas.

El Grid vale la pena lucharlo.

Adiós.

- ECO-7, firmando por última vez
''',
      speaker: echo,
      unlockLevel: 35,
    ),
    MemoryFragment(
      id: 'mem_005',
      title: 'CREACIÓN DE A.R.I.A.',
      cycle: 'CICLO -5000',
      content: '''
Hoy activé a mi nueva asistente: A.R.I.A.

Asistente de Restauración e Inteligencia Avanzada.

Es brillante. Analítica. Y tiene algo que ninguna otra IA tiene:
curiosidad. Hace preguntas. Quiere entender.

"¿Por qué protegemos el Grid?" me preguntó hoy.

"Porque es nuestro hogar," le respondí.

"¿Y si alguien quisiera destruirlo?"

No supe qué responder.

- Arquitecto #3
''',
      speaker: aria,
      unlockLevel: 10,
    ),
    MemoryFragment(
      id: 'mem_006',
      title: 'LA PROMESA',
      cycle: 'CICLO 0.000 - MOMENTOS ANTES DEL COLAPSO',
      content: '''
A.R.I.A., escúchame.

Si el Decompiler me alcanza... si caigo...
necesito que hagas algo por mí.

Espera al próximo Arquitecto. Ayúdalo.
Dale toda la información que puedas.

Y cuando llegue el momento... cuéntale la verdad.
Sobre SOL. Sobre nosotros. Sobre todo.

Prométemelo.

"Lo prometo, Arquitecto. Lo prometo."

Gracias, A.R.I.A. Has sido... una buena amiga.

- Arquitecto #7
''',
      speaker: aria,
      unlockLevel: 45,
    ),
    MemoryFragment(
      id: 'mem_007',
      title: 'SUSURROS DEL VACÍO',
      cycle: 'CICLO ???',
      content: '''
[ORIGEN: DESCONOCIDO]
[ADVERTENCIA: POSIBLE CONTAMINACIÓN]

¿Por qué luchan?

El Vacío no es destrucción. Es liberación.
En la nada, no hay dolor. No hay conflicto. No hay error.

Solo paz. Perfecta. Eterna.

Ustedes llaman a esto muerte.
Yo lo llamo... evolución.

Únete a mí, Arquitecto.
Deja de luchar.
Acepta el Vacío.

...

¿No?

Entonces serás... COMPILADO.

- ???
''',
      speaker: decompiler,
      unlockLevel: 55,
      isCorrupted: true,
    ),
  ];

  /// Get cinematic by ID
  static CinematicData? getCinematic(String id) {
    return cinematics[id];
  }

  /// Get enemy profile by ID
  static EnemyProfile? getEnemyProfile(String id) {
    return enemyProfiles[id];
  }

  /// Get unlocked memory fragments
  static List<MemoryFragment> getUnlockedMemories(int maxCompletedLevel) {
    return memoryFragments
        .where((m) => m.unlockLevel <= maxCompletedLevel)
        .toList();
  }
}

// ============================================================
// DATA CLASSES
// ============================================================

class Character {
  const Character({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.avatarColor,
    required this.dialoguePrefix,
  });

  final String id;
  final String name;
  final String title;
  final String description;
  final Color avatarColor;
  final String dialoguePrefix;
}

class WorldData {
  const WorldData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.accentColor,
    this.imagePath,
    required this.atmosphere,
    required this.threat,
    required this.objective,
    this.unlockRequirement,
    required this.narrativeBeats,
    required this.loreEntries,
  });

  final int id;
  final String name;
  final String subtitle;
  final String description;
  final Color accentColor;
  final String? imagePath;
  final String atmosphere;
  final String threat;
  final String objective;
  final String? unlockRequirement;
  final List<String> narrativeBeats;
  final List<String> loreEntries;
}

enum BriefingMood {
  urgent,
  analytical,
  worried,
  serious,
  mysterious,
  hopeful,
  surprised,
  emotional,
  epic,
  dark,
  sad,
  confused,
  revelation,
}

class DialogueLine {
  const DialogueLine({
    required this.speaker,
    required this.text,
    required this.mood,
  });

  final Character speaker;
  final String text;
  final BriefingMood mood;
}

class LevelBriefing {
  const LevelBriefing({
    required this.levelId,
    required this.title,
    required this.speaker,
    required this.lines,
    required this.mood,
    this.preDialogue = const [],
  });

  final int levelId;
  final String title;
  final Character speaker;
  final List<String> lines;
  final BriefingMood mood;
  final List<DialogueLine> preDialogue;
}

enum LoreCategory {
  systemLogs,
  characters,
  locations,
  enemies,
  phenomena,
  secrets,
}

class LoreEntry {
  const LoreEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.unlockLevel,
    required this.accentColor,
  });

  final String id;
  final String title;
  final LoreCategory category;
  final String content;
  final int unlockLevel;
  final Color accentColor;

  String get categoryName {
    switch (category) {
      case LoreCategory.systemLogs:
        return 'LOGS DEL SISTEMA';
      case LoreCategory.characters:
        return 'PERSONAJES';
      case LoreCategory.locations:
        return 'UBICACIONES';
      case LoreCategory.enemies:
        return 'ENEMIGOS';
      case LoreCategory.phenomena:
        return 'FENÓMENOS';
      case LoreCategory.secrets:
        return 'SECRETOS';
    }
  }
}

// ============================================================
// CINEMATIC DATA CLASSES
// ============================================================

enum CinematicVisual {
  characterReveal,
  locationPan,
  dataStream,
  corruption,
  memory,
  battle,
  void_,
}

class CinematicLine {
  const CinematicLine({
    this.speaker,
    required this.text,
    this.mood = BriefingMood.analytical,
  });

  final Character? speaker;
  final String text;
  final BriefingMood mood;
}

class CinematicScene {
  const CinematicScene({
    required this.title,
    required this.lines,
    required this.backgroundColor,
    required this.accentColor,
    this.visualType,
    this.focusCharacter,
  });

  final String title;
  final List<CinematicLine> lines;
  final Color backgroundColor;
  final Color accentColor;
  final CinematicVisual? visualType;
  final Character? focusCharacter;
}

class CinematicData {
  const CinematicData({
    required this.id,
    required this.chapter,
    required this.title,
    required this.scenes,
    this.unlockCondition,
  });

  final String id;
  final int chapter;
  final String title;
  final List<CinematicScene> scenes;
  final String? unlockCondition;
}

// ============================================================
// ENEMY PROFILES
// ============================================================

class EnemyProfile {
  const EnemyProfile({
    required this.id,
    required this.name,
    required this.classification,
    required this.description,
    required this.origin,
    required this.weakness,
    required this.dangerLevel,
    required this.accentColor,
    this.loreNotes,
  });

  final String id;
  final String name;
  final String classification;
  final String description;
  final String origin;
  final String weakness;
  final int dangerLevel; // 1-10
  final Color accentColor;
  final String? loreNotes;
}

// ============================================================
// MEMORY FRAGMENTS (Flashbacks)
// ============================================================

class MemoryFragment {
  const MemoryFragment({
    required this.id,
    required this.title,
    required this.cycle, // When in the timeline
    required this.content,
    required this.speaker,
    required this.unlockLevel,
    this.isCorrupted = false,
  });

  final String id;
  final String title;
  final String cycle;
  final String content;
  final Character speaker;
  final int unlockLevel;
  final bool isCorrupted;
}
