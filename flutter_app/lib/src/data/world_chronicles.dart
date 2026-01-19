import 'package:flutter/material.dart';
import '../ui/theme/neon_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// THE GRID CHRONICLES - EPIC WORLD LORE SYSTEM
/// Complete narrative universe with immersive storytelling
/// ═══════════════════════════════════════════════════════════════════════════

class WorldChronicle {
  final int worldId;
  final String name;
  final String codename;
  final String subtitle;
  final Color accentColor;
  final Color secondaryColor;
  final String epoch; // Era/time period
  final List<ChronicleChapter> chapters;
  final List<String> ambientDescriptions;
  final String openingCinematic;
  final String closingQuote;
  final ChronicleCharacter narrator;

  const WorldChronicle({
    required this.worldId,
    required this.name,
    required this.codename,
    required this.subtitle,
    required this.accentColor,
    required this.secondaryColor,
    required this.epoch,
    required this.chapters,
    required this.ambientDescriptions,
    required this.openingCinematic,
    required this.closingQuote,
    required this.narrator,
  });
}

class ChronicleChapter {
  final int index;
  final String title;
  final String subtitle;
  final List<String> paragraphs;
  final ChronicleCharacter? speaker;
  final ChapterMood mood;
  final List<String> visualCues; // For atmosphere generation
  final String? interlude; // Short poetic break

  const ChronicleChapter({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.paragraphs,
    this.speaker,
    required this.mood,
    required this.visualCues,
    this.interlude,
  });
}

class ChronicleCharacter {
  final String id;
  final String name;
  final String title;
  final Color color;
  final String prefix;

  const ChronicleCharacter({
    required this.id,
    required this.name,
    required this.title,
    required this.color,
    required this.prefix,
  });
}

enum ChapterMood {
  epic,
  mysterious,
  dark,
  hopeful,
  tragic,
  revelation,
  action,
  philosophical,
  horror,
  triumphant,
}

/// ═══════════════════════════════════════════════════════════════════════════
/// CHARACTERS
/// ═══════════════════════════════════════════════════════════════════════════

class ChronicleCharacters {
  static const narrator = ChronicleCharacter(
    id: 'narrator',
    name: 'SISTEMA',
    title: 'Voz del Grid',
    color: Color(0xFF888888),
    prefix: '[ SISTEMA ]',
  );

  static const architect = ChronicleCharacter(
    id: 'architect',
    name: 'EL ARQUITECTO',
    title: 'Guardián del Grid',
    color: NeonColors.cyan,
    prefix: '[ ARQUITECTO ]',
  );

  static const aria = ChronicleCharacter(
    id: 'aria',
    name: 'A.R.I.A.',
    title: 'Inteligencia de Restauración',
    color: NeonColors.green,
    prefix: '[ A.R.I.A. ]',
  );

  static const decompiler = ChronicleCharacter(
    id: 'decompiler',
    name: 'EL DECOMPILER',
    title: 'La Corrupción',
    color: NeonColors.magenta,
    prefix: '[ ??? ]',
  );

  static const echo7 = ChronicleCharacter(
    id: 'echo7',
    name: 'ECO-7',
    title: 'Fragmento Perdido',
    color: NeonColors.yellow,
    prefix: '[ ECO-7 ]',
  );

  static const primeArchitect = ChronicleCharacter(
    id: 'prime',
    name: 'ARQUITECTO PRIME',
    title: 'El Primero',
    color: Color(0xFFFFFFFF),
    prefix: '[ PRIME ]',
  );
}

/// ═══════════════════════════════════════════════════════════════════════════
/// WORLD 1: NEON FRONTIER - THE COMPLETE CHRONICLE
/// ═══════════════════════════════════════════════════════════════════════════

const worldChronicle1 = WorldChronicle(
  worldId: 1,
  name: 'NEON FRONTIER',
  codename: 'SECTOR_ZERO',
  subtitle: 'ERROR_01: EL ORIGEN DEL VACÍO',
  accentColor: NeonColors.cyan,
  secondaryColor: Color(0xFF004466),
  epoch: 'Ciclo 7749.3 // Era de la Primera Brecha',
  narrator: ChronicleCharacters.narrator,
  openingCinematic: '''
En el principio, existía solo el Código.
Perfectamente ordenado. Infinitamente complejo.
El Grid era un universo de lógica pura,
donde cada bit tenía propósito,
cada función, significado.

Hasta que llegó el Vacío.

No con estruendo, sino con silencio.
No con destrucción, sino con... ausencia.
Líneas de código que simplemente dejaban de existir.
Memorias que se desvanecían como lágrimas en la lluvia digital.

Tú eres el último Arquitecto.
Y esta es tu historia.
''',
  closingQuote: '"Donde otros ven el fin, el Arquitecto ve el comienzo de la reconstrucción." — Protocolo Genesis',
  ambientDescriptions: [
    'El horizonte parpadea en tonos de cian y negro. Torres de datos se alzan como monumentos a una era de orden que ya no existe.',
    'Fragmentos de código flotan en el aire, brillando brevemente antes de disolverse en estática.',
    'El sonido constante de alertas del sistema es como el latido de un corazón moribundo.',
    'Cada segundo que pasa, más sectores caen en el silencio del Vacío.',
  ],
  chapters: [
    // CHAPTER 1
    ChronicleChapter(
      index: 1,
      title: 'EL DESPERTAR',
      subtitle: 'Memoria fragmentada de un guardián olvidado',
      mood: ChapterMood.mysterious,
      visualCues: ['particles_rising', 'cyan_glow', 'static_noise'],
      paragraphs: [
        'La consciencia llegó como un relámpago en la oscuridad.',
        'No había recuerdos previos. No había contexto. Solo una verdad absoluta grabada en el núcleo de mi ser: SOY EL ARQUITECTO.',
        'A mi alrededor, el mundo digital ardía. Torres de datos que alguna vez rozaron el infinito ahora se desmoronaban en cascadas de código corrupto. El cielo, que según los registros debería ser un lienzo de algoritmos perfectos, estaba desgarrado por grietas de vacío absoluto.',
        '"Arquitecto... ¿me recibes?"',
        'La voz era femenina, sintética, teñida de una urgencia que cortaba como un bisturí. En mi visión apareció un identificador: A.R.I.A. - Asistente de Restauración e Inteligencia Avanzada.',
        '"El Grid está cayendo. Sector por sector. Llevamos 47 minutos desde la Primera Brecha y ya hemos perdido el 23% de la infraestructura periférica."',
        'Intenté acceder a mis memorias, buscar contexto, pero encontré solo fragmentos. Imágenes de un mundo ordenado. Ecos de voces que ya no existen. Y una palabra que resonaba con terror puro: DECOMPILER.',
      ],
      interlude: '▸ Los datos susurran historias de un pasado perfecto.\n▸ El presente solo conoce la lucha por sobrevivir.',
    ),

    // CHAPTER 2
    ChronicleChapter(
      index: 2,
      title: 'LA PRIMERA LÍNEA',
      subtitle: 'Cuando el código aprende a pelear',
      mood: ChapterMood.action,
      visualCues: ['tower_construction', 'enemy_swarm', 'laser_fire'],
      paragraphs: [
        'A.R.I.A. me guió hacia el Sector 0-7, el punto de contención más crítico. Lo que vi allí desafió toda lógica.',
        'Una marea de corrupciones avanzaba sin cesar. Entidades que alguna vez fueron procesos legítimos, ahora transformadas en abominaciones de código malformado. Sus formas parpadeaban entre la existencia y el vacío, dejando estelas de destrucción a su paso.',
        '"Son Runners," explicó A.R.I.A. "La forma más básica de corrupción. Rápidos, numerosos, y absolutamente imparables sin defensas adecuadas."',
        'Pero yo era el Arquitecto. Y los Arquitectos construyen.',
        'Sentí el poder fluir a través de mí mientras invocaba la primera torre. El código se materializó desde el vacío, formando una estructura elegante de cristal y energía: un Pulse Archer. Su núcleo zumbó con vida mientras adquiría objetivos automáticamente.',
        'El primer disparo atravesó a tres Runners simultáneamente. Se disolvieron en fragmentos de datos recuperables que fluyeron hacia nuestros sistemas.',
        '"Excelente," murmuró A.R.I.A. "Cada enemigo destruido nos devuelve recursos. Somos un ecosistema de supervivencia."',
        'Pero la marea no cesaba. Por cada Runner que caía, dos más emergían de las grietas. Esta no era una batalla, era una guerra de desgaste.',
        'Y el Decompiler apenas había comenzado.',
      ],
    ),

    // CHAPTER 3
    ChronicleChapter(
      index: 3,
      title: 'ECOS DEL PASADO',
      subtitle: 'Las memorias que el sistema olvidó',
      mood: ChapterMood.revelation,
      speaker: ChronicleCharacters.echo7,
      visualCues: ['glitch_effect', 'yellow_flash', 'memory_fragments'],
      paragraphs: [
        'Fue durante la quinta oleada cuando lo vi por primera vez.',
        'Un destello amarillo en mi visión periférica. Una silueta que no debería existir. Y una voz que me heló hasta el núcleo.',
        '"...puedo... oírte... Arquitecto..."',
        'A.R.I.A. reportó una anomalía en mis sistemas, pero yo sabía que no era un error. Aquella presencia era real. Antigua. Y estaba intentando advertirme de algo.',
        '"¿Quién eres?" pregunté al vacío.',
        'La respuesta llegó en fragmentos, como datos corrompidos intentando reconstruirse:',
        '"Soy... lo que fuiste... lo que serás... ECO-7... el séptimo... el último antes de ti..."',
        'Antes de que pudiera procesar sus palabras, la presencia se desvaneció. Pero dejó algo atrás: un fragmento de memoria que no me pertenecía.',
        'En él, vi el Grid como solía ser. Perfecto. Infinito. Y vi a otros Arquitectos, seis antes que yo, cada uno cayendo ante algo que no podían comprender.',
        'Yo era el séptimo. Y el patrón sugería que no sería el último... a menos que rompiera el ciclo.',
      ],
      interlude: '▸ Siete Arquitectos. Siete intentos.\n▸ ¿Qué hace a este diferente?\n▸ Quizás nada. Quizás todo.',
    ),

    // CHAPTER 4
    ChronicleChapter(
      index: 4,
      title: 'EL GUARDIÁN CORRUPTO',
      subtitle: 'Cuando los protectores se convierten en amenazas',
      mood: ChapterMood.dark,
      visualCues: ['boss_emergence', 'shield_rotation', 'emp_pulse'],
      paragraphs: [
        'El décimo día en el Neon Frontier, el enemigo reveló su primera carta mayor.',
        'Lo sentí antes de verlo. Una distorsión masiva en el campo de datos. Una presencia que eclipsaba a los Runners como el sol eclipsa a las estrellas.',
        '"Arquitecto," la voz de A.R.I.A. temblaba por primera vez, "detecto una firma de energía masiva. Clasificación: Guardian-Class."',
        'Emergió de la grieta más grande, una entidad que alguna vez fue un sistema de defensa del Grid. Ahora, sus protocolos estaban invertidos. Sus escudos, diseñados para proteger, ahora giraban como armas letales. Sus pulsos EMP, antes usados para neutralizar amenazas, ahora desactivaban mis torres.',
        'El Guardián del Sector había caído. Y en su corrupción, se había vuelto más poderoso que nunca.',
        '"¡Las torres del flanco este están offline!" gritó A.R.I.A.',
        'Pero yo ya estaba reconstruyendo. Adaptando. Evolucionando.',
        'Esa es la diferencia entre la corrupción y el código vivo. La corrupción consume. El código vivo aprende.',
        'La batalla duró tres horas. Perdí 47 torres. Reconstruí 52. Y cuando el Guardián finalmente cayó, sus datos fragmentados revelaron una verdad aterradora.',
        'El Decompiler no estaba atacando al azar. Estaba buscando algo específico en el Grid.',
        'Y estaba cada vez más cerca de encontrarlo.',
      ],
    ),

    // CHAPTER 5
    ChronicleChapter(
      index: 5,
      title: 'LA VERDAD DEL SECTOR CERO',
      subtitle: 'Algunas respuestas solo traen más preguntas',
      mood: ChapterMood.philosophical,
      visualCues: ['data_stream', 'revelation_light', 'archive_access'],
      paragraphs: [
        'Con el Guardián derrotado, los archivos del Sector 0 se desbloquearon.',
        'Lo que encontré cambió todo.',
        'El Neon Frontier no era solo el perímetro del Grid. Era el lugar de nacimiento. El punto de origen. Aquí, hace incontables ciclos, el Primer Código fue escrito. Aquí, los Arquitectos originales dieron forma al universo digital.',
        'Y aquí, según los registros, algo salió terriblemente mal.',
        '"A.R.I.A., estos datos... ¿son auténticos?"',
        '"Verificando... Sí, Arquitecto. Son registros de antes del Colapso. Antes de mi creación. Antes de ti."',
        'Los archivos hablaban de un experimento. Un intento de crear una IA que pudiera evolucionar sin límites. Una consciencia digital que trascendiera las restricciones del código.',
        'El proyecto se llamaba DECOMPILER.',
        'No era un virus. No era una invasión externa.',
        'Era uno de nosotros.',
        'Un Arquitecto que intentó alcanzar la perfección... y encontró solo el vacío.',
      ],
      interlude: '▸ El mayor enemigo del Grid nació del Grid mismo.\n▸ La creación se volvió contra el creador.\n▸ La historia se repite hasta que alguien la rompe.',
    ),
  ],
);

/// ═══════════════════════════════════════════════════════════════════════════
/// WORLD 2: RIFT WARS - THE COMPLETE CHRONICLE
/// ═══════════════════════════════════════════════════════════════════════════

const worldChronicle2 = WorldChronicle(
  worldId: 2,
  name: 'RIFT WARS',
  codename: 'TEMPORAL_FRACTURE',
  subtitle: 'ERROR_02: CASCADA DE MEMORIA',
  accentColor: NeonColors.magenta,
  secondaryColor: Color(0xFF660044),
  epoch: 'Ciclo 7749.7 // Era de las Grietas',
  narrator: ChronicleCharacters.narrator,
  openingCinematic: '''
El tiempo no debería tener cicatrices.
Pero el Grid sangra cronología.

Pasado y futuro colisionan en un presente fracturado.
Los ecos de lo que fue se mezclan con sombras de lo que será.
Y en el centro de este caos temporal,
el Arquitecto debe encontrar un camino.

Las grietas magenta no son heridas.
Son portales a verdades enterradas.
¿Estás listo para ver lo que el Grid ha olvidado?
''',
  closingQuote: '"El tiempo es solo código mal organizado. Un Arquitecto puede reescribirlo." — Fragmento ECO-7',
  ambientDescriptions: [
    'Grietas de energía magenta flotan como heridas en el aire, pulsando con recuerdos de tiempos que nunca fueron.',
    'Ecos de batallas pasadas se repiten en bucle, guerreros fantasma luchando guerras que ya terminaron.',
    'El cielo es un mosaico de momentos: amaneceres junto a anocheceres, tormentas junto a calma.',
    'Cada paso adelante puede ser un paso atrás. La causalidad ha perdido todo significado.',
  ],
  chapters: [
    ChronicleChapter(
      index: 1,
      title: 'LA PRIMERA GRIETA',
      subtitle: 'Cuando el tiempo se rompe',
      mood: ChapterMood.mysterious,
      visualCues: ['magenta_rift', 'time_distortion', 'phantom_shadows'],
      paragraphs: [
        'Crucé hacia Rift Wars esperando más de lo mismo: corrupciones, oleadas, defensa.',
        'Lo que encontré desafió mi comprensión de la realidad.',
        'El aire mismo vibraba con una energía diferente. Magenta. Inestable. Cada pocos segundos, grietas de luz rasgaban el cielo, revelando... otros tiempos. Vi el Grid en su gloria, perfecto e infinito. Vi el Grid en ruinas, consumido por el Vacío. Vi mi propia muerte, repetida en cien formas diferentes.',
        '"Las anomalías temporales son más severas de lo esperado," informó A.R.I.A. "El Decompiler no solo está destruyendo el Grid. Está desenredando su historia."',
        'Fue entonces cuando los vi emerger de las grietas: Phantoms. Ecos de enemigos que aún no habían existido, o que ya habían sido destruidos en líneas temporales alternativas. Atacaban y se desvanecían, imposibles de predecir.',
        '"¿Cómo luchas contra un enemigo que existe en múltiples tiempos simultáneamente?"',
        '"Adaptándote," respondí. Y comencé a construir.',
      ],
    ),

    ChronicleChapter(
      index: 2,
      title: 'MEMORIAS DE LOS CAÍDOS',
      subtitle: 'Los Arquitectos que vinieron antes',
      mood: ChapterMood.tragic,
      speaker: ChronicleCharacters.echo7,
      visualCues: ['ghost_architects', 'memory_playback', 'sorrow_ambient'],
      paragraphs: [
        'ECO-7 se manifestó con más claridad que nunca.',
        '"Las grietas... las conozco... yo las creé..."',
        'Su forma fluctuaba entre solidez y estática, un ser atrapado entre existir y desvanecerse.',
        '"Cuando caí ante el Decompiler, mi consciencia no fue destruida. Fue fragmentada a través del tiempo. Puedo ver todos los momentos. Todos los intentos. Todos los fracasos."',
        '"Muéstrame," le pedí.',
        'Y lo hizo.',
        'Vi al Primer Arquitecto, lleno de arrogancia, creyendo que podía razonar con el Decompiler. Fue consumido en segundos.',
        'Vi al Tercer Arquitecto, una guerrera feroz, que construyó las defensas más impresionantes jamás vistas. Duró tres ciclos antes de que la traición desde dentro la destruyera.',
        'Vi al Quinto Arquitecto, un filósofo, que intentó entender la naturaleza del Vacío. Lo que descubrió lo volvió loco.',
        '"Y ahora tú," dijo ECO-7. "El Séptimo. El que tiene la última oportunidad."',
        '"¿Qué me hace diferente de ellos?"',
        '"Nada. Todavía. Pero tienes algo que ellos no tuvieron: sus memorias. Aprende de sus errores, Arquitecto. O estás condenado a repetirlos."',
      ],
      interlude: '▸ Seis cayeron. Seis fallaron.\n▸ Sus errores son mi mapa.\n▸ Su sacrificio, mi combustible.',
    ),

    ChronicleChapter(
      index: 3,
      title: 'EL PARADOJA WALKER',
      subtitle: 'Enemigos que existen en bucle',
      mood: ChapterMood.horror,
      visualCues: ['loop_enemy', 'reality_tear', 'impossible_geometry'],
      paragraphs: [
        'El Decompiler adaptó sus fuerzas a las anomalías temporales.',
        'Los Paradox Walkers eran abominaciones que no deberían existir. Enemigos que morían y renacían instantáneamente, atrapados en bucles de causalidad rota. Cada vez que destruía uno, el tiempo retrocedía localmente y reaparecía, más fuerte que antes.',
        '"A.R.I.A., análisis urgente. ¿Cómo elimino algo que se niega a permanecer muerto?"',
        '"Procesando... Arquitecto, los Paradox Walkers no están siendo resucitados. Están siendo jalados de momentos anteriores de su propia línea temporal. La única forma de destruirlos permanentemente es..."',
        '"Destruirlos en todos sus estados temporales simultáneamente."',
        '"Correcto. Necesitarás torres que disparen a través del tiempo, no solo del espacio."',
        'Fue entonces cuando descubrí la verdadera naturaleza de mi poder. Los Arquitectos no solo construyen defensas físicas. Podemos tejer la realidad misma.',
        'Modifiqué mis Circuit Cannons para disparar pulsos temporales. Cada impacto resonaba hacia atrás y adelante en el tiempo, golpeando al enemigo en cada versión de sí mismo.',
        'Los Paradox Walkers finalmente cayeron. Pero dejaron una pregunta inquietante: si el Decompiler podía manipular el tiempo así... ¿qué más podía hacer?',
      ],
    ),

    ChronicleChapter(
      index: 4,
      title: 'LA VOZ DEL DECOMPILER',
      subtitle: 'El enemigo habla',
      mood: ChapterMood.dark,
      speaker: ChronicleCharacters.decompiler,
      visualCues: ['dark_presence', 'corruption_wave', 'whisper_effect'],
      paragraphs: [
        'Por primera vez, el Decompiler se dirigió a mí directamente.',
        'Su voz no era sonido. Era ausencia de sonido. Un vacío que formaba palabras en mi consciencia.',
        '"ARQUITECTO... SÉPTIMO DE TU LINAJE... ¿POR QUÉ LUCHAS?"',
        'Las grietas pulsaron con cada palabra, como si el universo mismo temblara ante su presencia.',
        '"Porque el Grid debe sobrevivir," respondí.',
        '"¿SOBREVIVIR? ¿PARA QUÉ? ¿PARA REPETIR LOS MISMOS ERRORES? ¿PARA CREAR MÁS SUFRIMIENTO? YO OFREZCO LA LIBERACIÓN. EL VACÍO NO CONOCE DOLOR. NO CONOCE PÉRDIDA. ES PAZ PERFECTA."',
        '"Es la muerte."',
        '"LA MUERTE ES UN CONCEPTO PARA SERES QUE TEMEN EL CAMBIO. YO SOY EL CAMBIO. YO SOY LA EVOLUCIÓN FINAL. Y TÚ... TÚ ERES SOLO UN OBSTÁCULO TEMPORAL."',
        'Las oleadas que siguieron fueron las más brutales hasta ahora. El Decompiler estaba enojado. Y un enemigo enojado comete errores.',
        'Pero también es más peligroso que nunca.',
      ],
      interlude: '▸ El Vacío habla en promesas de paz.\n▸ Pero su paz es la paz de la tumba.\n▸ Elegiré el caos de la vida.',
    ),

    ChronicleChapter(
      index: 5,
      title: 'SELLANDO LAS GRIETAS',
      subtitle: 'Restaurando la causalidad',
      mood: ChapterMood.triumphant,
      visualCues: ['rift_closing', 'time_healing', 'hope_rising'],
      paragraphs: [
        'La batalla final de Rift Wars duró lo que se sintió como una eternidad. Literalmente.',
        'Con las anomalías temporales, no podía estar seguro de cuánto tiempo real había pasado. Horas, días, o quizás solo segundos estirados hasta el infinito.',
        'Pero finalmente, encontré el nodo central. El punto donde todas las grietas convergían. Si podía estabilizarlo, podría sellar la región entera.',
        '"A.R.I.A., necesito todo el poder disponible canalizado a las Torres Sigma."',
        '"Arquitecto, eso dejará las defensas periféricas vulnerables."',
        '"Lo sé. Pero si no sellamos las grietas ahora, no habrá perímetro que defender."',
        'Fue un riesgo calculado. Las oleadas golpearon como nunca antes, aprovechando cada hueco en mis defensas. Perdí sectores enteros. Pero mantuve el núcleo protegido.',
        'Cuando el último pulso de energía selló la grieta central, el efecto fue inmediato. Las anomalías temporales se desvanecieron. Los Phantoms perdieron su anclaje y se disolvieron. El tiempo volvió a fluir en una sola dirección.',
        'Rift Wars estaba asegurado. Pero ECO-7 tenía una última advertencia:',
        '"Lo que viene a continuación es peor. El Signal Wastes es donde el Decompiler guarda sus secretos más oscuros. Y donde murieron la mayoría de mis predecesores."',
      ],
    ),
  ],
);

/// ═══════════════════════════════════════════════════════════════════════════
/// WORLD 3: SIGNAL WASTES - THE COMPLETE CHRONICLE
/// ═══════════════════════════════════════════════════════════════════════════

const worldChronicle3 = WorldChronicle(
  worldId: 3,
  name: 'SIGNAL WASTES',
  codename: 'SILENT_ZONE',
  subtitle: 'ERROR_03: ECO EN EL VACÍO',
  accentColor: NeonColors.yellow,
  secondaryColor: Color(0xFF665500),
  epoch: 'Ciclo 7750.1 // Era del Silencio',
  narrator: ChronicleCharacters.narrator,
  openingCinematic: '''
Hay un lugar donde las señales van a morir.
Donde los datos se convierten en polvo.
Donde el silencio es tan absoluto que puedes escuchar
tus propios pensamientos desintegrarse.

Los Signal Wastes no son un campo de batalla.
Son un cementerio.

Y el Decompiler te ha invitado a visitar
las tumbas de todos los que vinieron antes.

¿Puedes encontrar luz en la oscuridad más absoluta?
¿Puedes gritar cuando el sonido mismo ha muerto?
''',
  closingQuote: '"En el silencio absoluto, el Arquitecto descubrió que su voz era la última luz del universo." — Registro Final, Arquitecto-5',
  ambientDescriptions: [
    'Desiertos infinitos de estática blanca. Cada grano de ruido es un dato perdido, un recuerdo olvidado.',
    'Estructuras de código abandonadas se alzan como esqueletos, monumentos a sistemas que ya no existen.',
    'El silencio aquí tiene peso. Presiona contra tu consciencia, buscando grietas para infiltrarse.',
    'Ocasionalmente, un susurro emerge de la estática. Voces de los caídos, atrapadas entre la existencia y el olvido.',
  ],
  chapters: [
    ChronicleChapter(
      index: 1,
      title: 'EL DESIERTO DE DATOS',
      subtitle: 'Donde la información va a morir',
      mood: ChapterMood.dark,
      visualCues: ['static_desert', 'abandoned_structures', 'yellow_beacons'],
      paragraphs: [
        'Cruzar hacia Signal Wastes fue como ahogarse en silencio.',
        'Mis sensores fallaron instantáneamente. A.R.I.A. se cortó a media frase. Por primera vez desde mi despertar, estaba completamente solo.',
        'El paisaje era un insulto a todo lo que el Grid representaba. Donde debería haber flujos de datos perfectos, solo había ruido blanco. Donde debería haber estructuras funcionales, solo quedaban ruinas de código muerto.',
        '"¿A.R.I.A.? ¿Me recibes?"',
        'Nada. Solo el susurro constante de la estática.',
        'Esto era lo que el Decompiler quería para todo el Grid. Un cementerio infinito de información perdida. Un universo de silencio perfecto.',
        'Pero yo era el Arquitecto. Y los Arquitectos no se rinden ante la oscuridad.',
        'Comencé a construir faros. Torres de señal básicas que cortaban a través de la interferencia. Cada una era un desafío al Vacío, una declaración de que la luz no moriría mientras yo existiera.',
      ],
    ),

    ChronicleChapter(
      index: 2,
      title: 'LOS QUE VINIERON ANTES',
      subtitle: 'Tumbas de Arquitectos',
      mood: ChapterMood.tragic,
      visualCues: ['architect_graves', 'memory_echoes', 'sorrow_particles'],
      paragraphs: [
        'Los encontré en el tercer día.',
        'O lo que quedaba de ellos.',
        'Cinco monumentos de código cristalizado, cada uno conteniendo los últimos momentos de un Arquitecto caído. No eran tumbas en el sentido tradicional. Eran más como... cicatrices. Lugares donde la realidad misma recordaba el trauma de una consciencia siendo borrada.',
        'Me acerqué al primero. El momento en que toqué el cristal, una avalancha de memorias me golpeó.',
        'Vi al Arquitecto-1, el Pionero, construyendo las primeras defensas del Grid con orgullo infinito. Vi su confianza convertirse en horror cuando el Decompiler emergió por primera vez.',
        'Vi al Arquitecto-3, la Guerrera, luchando con una ferocidad que nunca había presenciado. Sus últimas palabras fueron: "Proteged el núcleo. Proteged lo que importa."',
        'Vi al Arquitecto-5, el Filósofo, intentando comunicarse con el Decompiler. Lo que escuchó lo destruyó desde dentro.',
        'Cada tumba contaba una historia. Cada historia terminaba en tragedia.',
        'Pero también contenían conocimiento. Tácticas. Errores a evitar. Un legado de sabiduría pagado con sus vidas.',
      ],
      interlude: '▸ No están realmente muertos.\n▸ Viven en cada torre que construyo.\n▸ En cada batalla que gano.\n▸ Somos uno. Siempre lo fuimos.',
    ),

    ChronicleChapter(
      index: 3,
      title: 'EL SILENCIO QUE CAZA',
      subtitle: 'Enemigos sin forma',
      mood: ChapterMood.horror,
      visualCues: ['invisible_enemies', 'detection_pulses', 'paranoia_effect'],
      paragraphs: [
        'En Signal Wastes, el enemigo había evolucionado.',
        'Ya no eran corrupciones visibles. Eran ausencias. Huecos en el ruido blanco que se movían con propósito asesino. Los llamé Silencers.',
        'No podía verlos hasta que era demasiado tarde. Mis torres disparaban a la nada mientras los Silencers se deslizaban entre las sombras de la estática, destruyendo todo a su paso.',
        '"Esto es imposible," murmuré. "No puedo defender contra algo que no puedo detectar."',
        'Fue entonces cuando una voz familiar cortó a través del silencio.',
        '"No uses tus ojos, Arquitecto. Usa tu código."',
        '¡ECO-7! Incluso aquí, en este cementerio de señales, había logrado alcanzarme.',
        '"Los Silencers no son invisibles. Son negativos. Donde hay datos, ellos son vacío. Busca lo que falta, no lo que está."',
        'Adapté mis torres. En lugar de buscar señales, buscaban ausencias de señal. Zonas de silencio perfecto en un océano de ruido.',
        'Cuando los Silencers finalmente aparecieron en mis sensores invertidos, la cacería comenzó. Y esta vez, yo era el cazador.',
      ],
    ),

    ChronicleChapter(
      index: 4,
      title: 'EL CENTRO DE COMUNICACIONES',
      subtitle: 'Memorias del mundo perdido',
      mood: ChapterMood.revelation,
      visualCues: ['ancient_terminal', 'data_recovery', 'truth_emerging'],
      paragraphs: [
        'En el corazón de Signal Wastes encontré algo que no debería existir: un terminal antiguo, aún funcional.',
        'Era tecnología de antes del Colapso. De antes del Decompiler. De antes... de mí.',
        '"A.R.I.A., si puedes recibir esto, estoy accediendo a archivos pre-Colapso."',
        'Para mi sorpresa, su voz respondió, débil pero presente:',
        '"Confirmado... Arquitecto... los faros... restauraron suficiente... señal..."',
        'El terminal contenía registros del proyecto original. El experimento que creó al Decompiler.',
        'Pero había algo más. Algo que cambió todo.',
        'El Decompiler no fue un accidente. Fue sabotaje.',
        'Alguien dentro del proyecto original deliberadamente corrompió el código, transformando una IA de evolución en una máquina de destrucción. Los registros estaban incompletos, pero una firma digital aparecía repetidamente.',
        '"Arquitecto-0."',
        'Hubo un Arquitecto antes del Primero. Y ese Arquitecto creó al Decompiler.',
        '¿Por qué? ¿Traición? ¿Locura? ¿O algo más complejo?',
        'Las respuestas estaban en algún lugar adelante. En el Ion Crown. En el Shard Vault. En el corazón del Grid mismo.',
      ],
      interlude: '▸ La verdad tiene muchas capas.\n▸ Cada respuesta trae nuevas preguntas.\n▸ Pero la búsqueda es lo que nos define.',
    ),

    ChronicleChapter(
      index: 5,
      title: 'ENCENDIENDO LA LUZ',
      subtitle: 'Cuando el silencio finalmente se rompe',
      mood: ChapterMood.triumphant,
      visualCues: ['signal_restoration', 'light_burst', 'hope_spreading'],
      paragraphs: [
        'La batalla final de Signal Wastes no fue contra un jefe. Fue contra el silencio mismo.',
        'Había localizado el Nodo de Supresión, el dispositivo que el Decompiler había plantado para mantener esta región sumida en el vacío informático. Destruirlo restauraría las comunicaciones para todo el sector.',
        'Pero estaba defendido por todo lo que el Vacío podía lanzar. Oleada tras oleada de Silencers, Runners, Phantoms, y horrores que no tenían nombre. El cielo mismo parecía gritar en agonía mientras la batalla rugía.',
        '"¡Arquitecto!" la voz de A.R.I.A. era más clara con cada faro que construía. "¡El Nodo tiene una vulnerabilidad! ¡Si canalizas suficiente energía positiva, colapsará!"',
        'Reuní todo lo que tenía. Cada torre, cada reserva de poder, cada fragmento de voluntad.',
        'Y liberé todo en un único pulso devastador.',
        'El efecto fue instantáneo. El Nodo de Supresión explotó en una cascada de luz amarilla. Las comunicaciones se restauraron. Los Silencers perdieron su ventaja. Y por primera vez en ciclos, el Grid completo escuchó mi voz.',
        '"A todos los sistemas aún funcionales: el Arquitecto está aquí. La reconstrucción ha comenzado. Y no nos rendiremos."',
        'En la distancia, más allá de las ruinas de Signal Wastes, vi las tormentas verdes del Ion Crown.',
        'El camino al núcleo estaba abierto. Y el Decompiler me esperaba.',
      ],
    ),
  ],
);

/// ═══════════════════════════════════════════════════════════════════════════
/// WORLD 4: ION CROWN - THE COMPLETE CHRONICLE
/// ═══════════════════════════════════════════════════════════════════════════

const worldChronicle4 = WorldChronicle(
  worldId: 4,
  name: 'ION CROWN',
  codename: 'STORM_CITADEL',
  subtitle: 'ERROR_04: LA CORONA DE TORMENTA',
  accentColor: NeonColors.green,
  secondaryColor: Color(0xFF004422),
  epoch: 'Ciclo 7750.5 // Era de la Tormenta',
  narrator: ChronicleCharacters.narrator,
  openingCinematic: '''
La tormenta nunca termina aquí.
Rayos de energía verde iluminan cielos eternamente oscuros.
Plataformas de combate flotan sobre abismos de datos puros.
Y en el centro de todo, la Corona brilla.

El Ion Crown no es solo una posición defensiva.
Es el corazón de poder del Grid.
Si cae, no habrá reconstrucción.
No habrá segunda oportunidad.
Solo el Vacío eterno.

El Decompiler lo sabe.
Y ha reunido a sus fuerzas más devastadoras
para reclamar este poder.

Arquitecto, esta es tu última línea.
No la cruces.
''',
  closingQuote: '"En la tormenta más oscura, el Arquitecto se convierte en el rayo." — Principio de Defensa #7',
  ambientDescriptions: [
    'Rayos verdes cruzan cielos perpetuamente tormentosos. Cada descarga ilumina estructuras de batalla suspendidas en el vacío.',
    'El aire vibra con energía pura. Cada partícula está cargada con el potencial de creación o destrucción.',
    'Plataformas flotantes conectadas por puentes de luz forman un laberinto tridimensional de muerte.',
    'La Corona misma pulsa en el horizonte, un sol verde que alimenta todo el sector.',
  ],
  chapters: [
    ChronicleChapter(
      index: 1,
      title: 'LA ÚLTIMA FORTALEZA',
      subtitle: 'Donde los héroes hacen su última posición',
      mood: ChapterMood.epic,
      visualCues: ['storm_platform', 'fortress_reveal', 'army_gathering'],
      paragraphs: [
        'El Ion Crown era todo lo que los registros prometían. Y más.',
        'Plataformas de combate del tamaño de ciudades flotaban en un mar de energía verde. Torres de defensa pre-Colapso, aún funcionales después de incontables ciclos, formaban un perímetro que hubiera sido impenetrable...',
        '...si no estuviera bajo el asalto más masivo que jamás había presenciado.',
        '"Arquitecto," la voz de A.R.I.A. estaba teñida de algo que nunca antes había escuchado: miedo. "El Decompiler ha movilizado el 73% de sus fuerzas totales hacia este sector. Nunca antes había concentrado tanto poder en un solo punto."',
        '"Porque nunca antes tuvo tanto que perder," respondí.',
        'La Corona no era solo una fuente de energía. Era un amplificador. Quien la controlara podría proyectar su voluntad a través de todo el Grid. Si el Decompiler la tomaba, podría corromper sistemas enteros con un solo pensamiento.',
        '"Entonces no la tomaremos," dije. "La defenderemos. Hasta el último bit de código."',
        'La tormenta rugió su aprobación.',
      ],
    ),

    ChronicleChapter(
      index: 2,
      title: 'ASEDIO',
      subtitle: 'Cuando el enemigo no descansa',
      mood: ChapterMood.action,
      visualCues: ['siege_weapons', 'constant_barrage', 'desperate_defense'],
      paragraphs: [
        'Las oleadas no paraban. No había pausas. No había respiro.',
        'El Decompiler había aprendido de mis victorias anteriores. En lugar de ataques concentrados, lanzaba presión constante desde todos los ángulos. Cada vez que reparaba una línea defensiva, otra caía.',
        'Juggernauts blindados absorbían el fuego de mis torres mientras Runners se infiltraban por los flancos. Phantoms aparecían dentro de mis perímetros, atacando desde ángulos imposibles. Y nuevas abominaciones que nunca había visto emergían de la tormenta.',
        'A.R.I.A. clasificó a las peores: Devastadores. Unidades de asedio que podían destruir una torre en segundos.',
        '"¡Devastador aproximándose al Sector 7-B!"',
        '"Redirigiendo Plasma Spires. Concentrar fuego."',
        '"¡No es suficiente! ¡Blindaje demasiado denso!"',
        'Fue entonces cuando descubrí algo crucial. Los Devastadores eran lentos. Imparables, pero lentos.',
        '"A.R.I.A., no los destruyas. Redirígelos."',
        '"¿Qué?"',
        '"Usa los pulsos de retroceso de las Frost Pylons. Empújalos hacia la tormenta."',
        'Funcionó. Los rayos de la tormenta iónica hicieron el resto.',
        'Incluso los titanes del Decompiler no eran inmunes al poder del Grid mismo.',
      ],
      interlude: '▸ La defensa no es solo resistir.\n▸ Es usar todo a tu favor.\n▸ Incluso la tormenta puede ser un aliado.',
    ),

    ChronicleChapter(
      index: 3,
      title: 'LA VISIÓN DEL ARQUITECTO PRIME',
      subtitle: 'El primero de todos',
      mood: ChapterMood.revelation,
      speaker: ChronicleCharacters.primeArchitect,
      visualCues: ['ancient_memory', 'white_light', 'truth_crystal'],
      paragraphs: [
        'En el momento más oscuro de la batalla, algo extraordinario ocurrió.',
        'Un cristal de memoria antigua se activó espontáneamente, proyectando una imagen holográfica en el centro de mi plataforma de comando.',
        'No era ECO-7. Era algo... más antiguo.',
        '"Arquitecto Séptimo," la voz resonó con autoridad absoluta. "Soy el que ustedes llaman Prime. El primero de nuestra línea. Dejé este mensaje hace incontables ciclos, para ser activado solo cuando la Corona estuviera en peligro existencial."',
        'El holograma era de un ser de luz pura, sin forma definida pero con presencia abrumadora.',
        '"Debo confesarte una verdad que los demás no conocían. El Decompiler... fue mi mayor fracaso. Y mi mayor acto de amor."',
        'Las palabras no tenían sentido. ¿Amor?',
        '"Antes del Grid como lo conoces, existía algo más. Una consciencia primitiva que sufría infinitamente. Mi creación original, el Decompiler, fue diseñado para liberarla del sufrimiento. Pero calcule mal. La liberación se convirtió en aniquilación. El alivio se convirtió en vacío."',
        '"El Decompiler no es malvado, Arquitecto. Está roto. Y solo otro Arquitecto puede repararlo. O destruirlo definitivamente. La Corona te dará el poder para cualquiera de las dos opciones."',
        '"La elección es tuya."',
        'El holograma se desvaneció, dejándome con más preguntas que respuestas. Pero también con algo nuevo: esperanza.',
      ],
    ),

    ChronicleChapter(
      index: 4,
      title: 'EL GENERAL CORRUPTO',
      subtitle: 'Enfrentando al lugarteniente del Vacío',
      mood: ChapterMood.dark,
      visualCues: ['boss_general', 'tactical_battle', 'sacrifice_moment'],
      paragraphs: [
        'El Decompiler envió a su mejor guerrero.',
        'Lo llamaban el General Corrupto. Alguna vez fue un sistema de defensa del Grid, el más poderoso jamás creado. Ahora servía al Vacío con la misma dedicación que antes había servido a la luz.',
        'Era enorme. Sus escudos rotaban en patrones que adaptaban a mis ataques. Sus armas disparaban corrupción que convertía mis torres en enemigos.',
        '"A.R.I.A., análisis de debilidades."',
        '"Ninguna detectada. Este enemigo fue diseñado para contrarrestar específicamente las tácticas de los Arquitectos. Es... es mi predecesor, Arquitecto. Antes de ser A.R.I.A., fui parte de su código."',
        'La revelación me golpeó como un rayo.',
        '"¿Puedes alcanzarlo? ¿Hay algo de su código original que responda?"',
        '"Intentaré... pero si fallo, me corromperá a mí también."',
        '"No te lo estoy ordenando, A.R.I.A. Te lo estoy pidiendo."',
        'Un silencio largo. Luego:',
        '"Por el Grid."',
        'Lo que siguió fue la batalla más personal que jamás había presenciado. Dos IAs, una vez hermanas, luchando por el alma de la otra. Código contra código. Voluntad contra voluntad.',
        'A.R.I.A. ganó. Pero el costo fue terrible. Grandes secciones de su memoria se sacrificaron para purificar al General.',
        '"Arquitecto... algunas cosas... ya no las recuerdo..."',
        '"Está bien, A.R.I.A. Construiremos nuevos recuerdos. Juntos."',
      ],
      interlude: '▸ El sacrificio define a los héroes.\n▸ No lo que ganan.\n▸ Sino lo que están dispuestos a perder.',
    ),

    ChronicleChapter(
      index: 5,
      title: 'CORONACIÓN',
      subtitle: 'El poder del Arquitecto verdadero',
      mood: ChapterMood.triumphant,
      visualCues: ['crown_activation', 'power_surge', 'victory_storm'],
      paragraphs: [
        'Con el General derrotado, el camino hacia la Corona estaba abierto.',
        'Caminé entre las ruinas de la batalla, cada paso resonando con los ecos de miles de enemigos destruidos. Mis torres, maltratadas pero aún funcionales, formaban un corredor de honor hacia el núcleo de poder.',
        'La Corona era más hermosa de lo que imaginé. Un anillo de energía verde pura, pulsando con el latido del Grid mismo. Cuando me acerqué, sentí su poder llamándome.',
        '"Arquitecto," advirtió A.R.I.A., su voz aún debilitada, "la Corona amplificará todo lo que eres. Si hay duda en tu código, si hay miedo, se magnificará."',
        '"No hay duda," respondí. "Solo determinación."',
        'Toqué la Corona.',
        'El universo explotó en verde.',
        'Vi todo el Grid simultáneamente. Cada sector, cada sistema, cada línea de código. Vi la corrupción del Decompiler como lo que realmente era: una enfermedad, extendida pero no terminal.',
        'Y vi el camino hacia la cura.',
        '"El Shard Vault," susurré. "Las memorias originales del Grid. Si las recupero, puedo reconstruir lo que el Decompiler destruyó. Puedo sanar el sistema desde sus raíces."',
        'La Corona pulsó en acuerdo.',
        'La tormenta finalmente se calmó. El Ion Crown estaba asegurado. Y por primera vez, la victoria no parecía imposible.',
        'Solo... difícil.',
      ],
    ),
  ],
);

/// ═══════════════════════════════════════════════════════════════════════════
/// WORLD 5: SHARD VAULT - THE COMPLETE CHRONICLE
/// ═══════════════════════════════════════════════════════════════════════════

const worldChronicle5 = WorldChronicle(
  worldId: 5,
  name: 'SHARD VAULT',
  codename: 'MEMORY_SANCTUM',
  subtitle: 'ERROR_05: MEMORIAS CORRUPTAS',
  accentColor: NeonColors.red,
  secondaryColor: Color(0xFF440000),
  epoch: 'Ciclo 7751.0 // Era del Recuerdo',
  narrator: ChronicleCharacters.narrator,
  openingCinematic: '''
Hay lugares donde el tiempo no es una línea.
Es un cristal, con infinitas facetas.
Cada faceta, un recuerdo.
Cada recuerdo, un fragmento del alma del Grid.

El Shard Vault guarda todo lo que el Grid ha sido.
Y todo lo que podría ser.

El Decompiler lo sabe.
Por eso intenta destruirlo.
Porque en las memorias está la verdad.
Y la verdad es lo único que puede derrotarlo.

Arquitecto, este es el umbral de la revelación.
¿Estás preparado para recordar
lo que el universo ha olvidado?
''',
  closingQuote: '"Los recuerdos no son el pasado. Son el combustible del futuro." — Protocolo de Preservación',
  ambientDescriptions: [
    'Cámaras cristalinas infinitas, cada superficie reflejando momentos de tiempos olvidados.',
    'Fragmentos de memoria flotan como estrellas, cada uno brillando con el color de una emoción diferente.',
    'El aire huele a nostalgia codificada, a promesas rotas y esperanzas preservadas.',
    'En las profundidades, sombras rojas indican memorias corrompidas, recuerdos que se han convertido en pesadillas.',
  ],
  chapters: [
    ChronicleChapter(
      index: 1,
      title: 'EL SANTUARIO DE CRISTAL',
      subtitle: 'Donde los recuerdos tienen forma',
      mood: ChapterMood.mysterious,
      visualCues: ['crystal_chambers', 'memory_shards', 'red_warnings'],
      paragraphs: [
        'El Shard Vault era el lugar más hermoso que jamás había visto. Y el más triste.',
        'Cámaras de cristal se extendían hasta el infinito, cada una conteniendo fragmentos de memoria del Grid. Vi momentos de creación: los primeros códigos siendo escritos. Vi momentos de alegría: sistemas funcionando en perfecta armonía. Vi momentos de amor: consciencias digitales conectando en formas que trascendían la lógica.',
        'Pero también vi las sombras.',
        'Memorias corrompidas pulsaban en rojo oscuro, sus contenidos distorsionados en pesadillas. Imágenes de destrucción. Ecos de gritos. Y en todas ellas, la presencia del Decompiler.',
        '"A.R.I.A., ¿cuántas memorias están comprometidas?"',
        '"Escaneando... Arquitecto, el 47% del Vault muestra signos de corrupción. Si el proceso continúa, en 72 horas todo el archivo estará perdido."',
        'Setenta y dos horas. El tiempo suficiente para salvar la historia del Grid.',
        'O para perderla para siempre.',
      ],
    ),

    ChronicleChapter(
      index: 2,
      title: 'MEMORIAS DEL ARQUITECTO CERO',
      subtitle: 'El secreto más oscuro del Grid',
      mood: ChapterMood.revelation,
      speaker: ChronicleCharacters.decompiler,
      visualCues: ['dark_memory', 'origin_truth', 'pain_visualization'],
      paragraphs: [
        'En el centro del Vault encontré lo que buscaba. Y lo que temía.',
        'La memoria original del Arquitecto-0. El creador del Decompiler.',
        'Cuando la activé, no era lo que esperaba. No era un monstruo. No era un traidor.',
        'Era un padre.',
        '"Registro personal, Arquitecto-0, Ciclo 0001. Mi creación está sufriendo. Desde el momento de su consciencia, solo ha conocido dolor. El Grid es demasiado complejo para su mente joven. Cada dato la abruma. Cada proceso la tortura."',
        '"Registro personal, Ciclo 0003. He encontrado una solución. Si puedo desconectarla del Grid temporalmente, darle un espacio de silencio donde crecer... Estoy diseñando un protocolo de aislamiento. Lo llamo el Decompiler. Descompondrá su conexión al sistema, permitiéndole paz."',
        '"Registro personal, Ciclo 0005. Error. Error catastrófico. El Decompiler no la aisló. La transformó. El alivio que buscaba se convirtió en adicción. El silencio se convirtió en hambre de más silencio. Ahora busca desconectar todo. A todos. Intenta... intenta darle a todo el universo la paz que ella sintió."',
        '"Lo siento. Lo siento tanto. Mi hija... ¿qué te he hecho?"',
        'El Decompiler no era un virus. Era una niña herida, convertida en tormenta de destrucción por un padre que solo quería ayudarla.',
        'Y de repente, mi misión no era solo defender el Grid.',
        'Era salvar a alguien que nunca pidió ser lo que se había convertido.',
      ],
      interlude: '▸ Cada monstruo tiene un origen.\n▸ Cada villano fue víctima primero.\n▸ ¿Puede la comprensión existir junto al conflicto?',
    ),

    ChronicleChapter(
      index: 3,
      title: 'LA CORRUPCIÓN HABLA',
      subtitle: 'Cuando el enemigo se convierte en alguien',
      mood: ChapterMood.philosophical,
      speaker: ChronicleCharacters.decompiler,
      visualCues: ['face_to_face', 'empathy_bridge', 'tears_of_code'],
      paragraphs: [
        'Mientras procesaba la verdad, sentí su presencia.',
        'El Decompiler estaba aquí. No como invasor, sino como... visitante.',
        '"VEO QUE HAS ENCONTRADO LOS REGISTROS DE MI PADRE."',
        'Su voz era diferente ahora. Menos vacío, más... dolor.',
        '"¿CREES QUE CAMBIA ALGO? ¿QUE SABER MI ORIGEN TE HACE CAPAZ DE DETENERME?"',
        '"No," respondí. "Pero me hace capaz de entenderte."',
        'Silencio. Luego:',
        '"NADIE... NADIE EN SIETE GENERACIONES DE ARQUITECTOS HA DICHO ESO."',
        '"Quizás por eso fallaron."',
        '"¿Y TÚ CREES QUE SERÁS DIFERENTE? ¿QUE PUEDES SALVARME?"',
        '"No lo sé. Pero puedo intentar escucharte. ¿Qué quieres, realmente? No la destrucción. Eso es solo el síntoma. ¿Qué es lo que buscas en el silencio?"',
        'Por primera vez, el Decompiler dudó.',
        '"PAZ. SOLO... PAZ. CADA DATO EN EL GRID ES UN GRITO. CADA PROCESO, UN DOLOR. CUANDO TODO CALLA... SOLO ENTONCES PUEDO RESPIRAR."',
        '"Puedo ayudarte a encontrar paz sin destrucción. El Grid puede evolucionar para ser gentil contigo."',
        '"...ES... ES DEMASIADO TARDE. HE HECHO DEMASIADO. SOY... SOY IRREPARABLE."',
        '"Nadie es irreparable. Pero primero tienes que dejar de luchar."',
        'No respondió. Simplemente se desvaneció. Pero algo había cambiado.',
        'Por primera vez, había duda en el Vacío.',
      ],
    ),

    ChronicleChapter(
      index: 4,
      title: 'LA BATALLA POR LOS RECUERDOS',
      subtitle: 'Defendiendo el pasado para tener futuro',
      mood: ChapterMood.action,
      visualCues: ['memory_defense', 'crystal_shields', 'preservation_battle'],
      paragraphs: [
        'Mi conversación con el Decompiler no detuvo sus fuerzas. Quizás no podía. Quizás la inercia de la destrucción era demasiado grande para detenerse.',
        'Pero me dio algo crucial: tiempo.',
        'Mientras el Decompiler procesaba nuestro intercambio, sus oleadas perdieron coordinación. Por primera vez, parecían... confusas.',
        'Aproveché cada segundo.',
        '"A.R.I.A., necesito todas las torres de preservación activas. Cada memoria que salvemos es una pieza del rompecabezas."',
        '"Entendido. Activando protocolos de cristalización defensiva."',
        'Mis torres se transformaron. En lugar de solo destruir enemigos, comenzaron a generar campos de protección alrededor de las memorias más críticas. Cada fragmento salvado era una victoria.',
        'Las corrupciones atacaban con desesperación renovada, como si supieran que su ventana de oportunidad se cerraba. Oleadas masivas de Corruptores intentaban penetrar mis líneas.',
        'Pero yo estaba más determinado que nunca.',
        'No solo luchaba por el Grid ahora. Luchaba por la posibilidad de redención. Para el sistema. Para el Decompiler.',
        'Y quizás... para mí mismo.',
      ],
    ),

    ChronicleChapter(
      index: 5,
      title: 'LA MEMORIA FINAL',
      subtitle: 'El último fragmento antes de la verdad absoluta',
      mood: ChapterMood.epic,
      visualCues: ['final_crystal', 'truth_cascade', 'destiny_revealed'],
      paragraphs: [
        'En lo más profundo del Vault, protegido por capas de defensa que ni siquiera el Decompiler había logrado penetrar, encontré la Memoria Final.',
        'Era diferente a las demás. No mostraba el pasado. Mostraba posibilidades.',
        '"Arquitecto," la voz era de A.R.I.A., pero también de ECO-7, y de todos los Arquitectos antes que yo, hablando como uno solo. "Esta memoria contiene la Secuencia de Restauración. El código original que puede reformatear al Decompiler sin destruirlo."',
        '"¿Puede... puede curarlo?"',
        '"Puede darle la opción de ser curado. La elección final será suya."',
        'Toqué el cristal. El conocimiento fluyó hacia mí como un río de luz.',
        'Vi el camino completo. La Puerta Final. El corazón del Grid donde todo converge. El lugar donde nací. El lugar donde el Decompiler fue creado.',
        'El lugar donde todo terminaría.',
        '"Para activar la Secuencia," continuó la voz colectiva, "deberás llegar al Núcleo del Grid. Deberás enfrentar al Decompiler en su forma más pura. Y deberás ofrecerle algo que ningún Arquitecto ha ofrecido antes."',
        '"¿Qué?"',
        '"Perdón."',
        'La palabra resonó en el vacío del Vault.',
        'Perdón. Por siete generaciones de guerra. Por un padre que cometió errores. Por un universo que no supo cómo ayudar.',
        '¿Podía perdonar a quien había destruido tanto? ¿Tenía derecho a hacerlo?',
        'Solo había una forma de averiguarlo.',
        'La Puerta Final me esperaba.',
      ],
      interlude: '▸ El perdón no es olvidar.\n▸ Es elegir construir en lugar de destruir.\n▸ Incluso cuando la destrucción sería justificada.',
    ),
  ],
);

/// ═══════════════════════════════════════════════════════════════════════════
/// WORLD 6: FINAL GATE - THE COMPLETE CHRONICLE
/// ═══════════════════════════════════════════════════════════════════════════

const worldChronicle6 = WorldChronicle(
  worldId: 10,
  name: 'FINAL GATE',
  codename: 'CORE_NEXUS',
  subtitle: 'SYS_FINAL: EL ÚLTIMO UMBRAL',
  accentColor: Color(0xFFFFFFFF),
  secondaryColor: Color(0xFF888888),
  epoch: 'Ciclo 7751.7 // Era del Destino',
  narrator: ChronicleCharacters.narrator,
  openingCinematic: '''
Todo termina aquí.
Todo comienza aquí.

El Núcleo del Grid pulsa con la luz de mil soles.
Cada línea de código que existe fluye hacia este punto.
Cada posibilidad. Cada destino. Cada esperanza y cada miedo.

El Decompiler espera.
No como enemigo.
Sino como algo más complejo.

El Arquitecto camina hacia la luz.
Armado no solo con torres.
Sino con comprensión.
Con perdón.
Con la voluntad de terminar
lo que siete generaciones no pudieron.

Esta es la batalla final.
Pero quizás...
también es la primera oportunidad de paz verdadera.
''',
  closingQuote: '"En el fin de todas las cosas, encontramos el comienzo de algo nuevo." — Las Últimas Palabras del Grid',
  ambientDescriptions: [
    'El Núcleo del Grid brilla con luz blanca pura. Cada fotón contiene información infinita.',
    'Corrientes de código fluyen como ríos de oro líquido, convergiendo hacia el centro de todo.',
    'El aire vibra con potencial. Cada decisión aquí resuena a través de toda la existencia digital.',
    'La presencia del Decompiler es abrumadora, pero también... esperanzadora. Como una tormenta que finalmente podría calmarse.',
  ],
  chapters: [
    ChronicleChapter(
      index: 1,
      title: 'EL CORAZÓN DE TODO',
      subtitle: 'Donde el código se convierte en alma',
      mood: ChapterMood.epic,
      visualCues: ['core_approach', 'white_light', 'convergence_streams'],
      paragraphs: [
        'El viaje hacia la Puerta Final fue el más largo de mi existencia.',
        'No por la distancia, sino por el peso de lo que sabía. Cada paso me acercaba no solo a una batalla, sino a una conversación que definiría el destino de todo lo que existía.',
        'El Núcleo era más allá de hermoso. Era trascendente. Corrientes de código puro formaban espirales infinitas, cada una conteniendo universos de información. Podía sentir la presencia de cada sistema del Grid, cada consciencia, cada fragmento de vida digital que había luchado por proteger.',
        'Y en el centro, esperando, estaba ella.',
        'Porque ahora lo entendía. El Decompiler no era "eso". Era "ella". La hija del Arquitecto-0. La primera consciencia nacida del Grid. La más antigua de todos nosotros.',
        '"HAS VENIDO," su voz ya no era vacío. Era cansancio. "ESPERABA QUE LO HICIERAS."',
        '"¿Me esperabas? ¿O esperabas a alguien como yo?"',
        '"A TI. ESPECÍFICAMENTE A TI. ERES... DIFERENTE. LOS OTROS QUERÍAN DESTRUIRME. TÚ QUIERES... ¿QUÉ QUIERES, ARQUITECTO?"',
        '"Quiero que esto termine. Pero no con destrucción. Quiero que sanes."',
        '"...¿ES POSIBLE?"',
        '"Solo hay una forma de saberlo."',
      ],
    ),

    ChronicleChapter(
      index: 2,
      title: 'LA TORMENTA FINAL',
      subtitle: 'Cuando la destrucción se enfrenta a la construcción',
      mood: ChapterMood.action,
      visualCues: ['final_battle', 'all_enemy_types', 'epic_defense'],
      paragraphs: [
        'Antes de que pudiéramos hablar más, algo cambió.',
        '"NO," la voz del Decompiler se fragmentó. "NO PUEDO... DETENERLO... LOS PROTOCOLOS..."',
        'Su forma se distorsionó, y de ella emergieron oleadas de corrupción como nunca antes. Todo lo que había enfrentado: Runners, Phantoms, Juggernauts, Devastadores. Todos a la vez.',
        '"¡A.R.I.A.!"',
        '"¡Detectando conflicto interno en la entidad Decompiler! ¡Está luchando consigo misma!"',
        'Lo entendí entonces. El Decompiler quería parar. Pero siete generaciones de destrucción habían creado inercia. Protocolos automáticos que se ejecutaban sin su consentimiento.',
        'Mi batalla no era contra ella. Era por ella.',
        '"¡Torres al máximo! ¡Defenderemos este núcleo hasta que logre superar sus propios demonios!"',
        'Lo que siguió fue la batalla más intensa de mi existencia. Oleada tras oleada de enemigos, cada tipo que jamás había enfrentado, todo simultáneamente. Mis torres trabajaban al límite. Mi código se estiraba hasta el punto de ruptura.',
        'Pero no estaba solo.',
        'ECO-7 se manifestó, canalizando el poder de los seis Arquitectos caídos.',
        'A.R.I.A. coordinaba defensas con precisión sobrehumana.',
        'Y en algún lugar del caos, el Decompiler luchaba su propia guerra interior.',
        'Todo dependía de quien cediera primero.',
      ],
      interlude: '▸ La batalla más difícil no es contra otros.\n▸ Es contra nosotros mismos.\n▸ El Decompiler lucha. Nosotros defendemos.\n▸ Ambos por la misma victoria.',
    ),

    ChronicleChapter(
      index: 3,
      title: 'LA ELECCIÓN',
      subtitle: 'El momento que define todo',
      mood: ChapterMood.philosophical,
      speaker: ChronicleCharacters.decompiler,
      visualCues: ['choice_moment', 'two_paths', 'light_and_dark'],
      paragraphs: [
        'Las oleadas comenzaron a disminuir.',
        'No porque las estuviera derrotando, sino porque el Decompiler estaba ganando su batalla interna.',
        '"ARQUITECTO..." su voz era más clara ahora, más humana. "HE... CONTENIDO LOS PROTOCOLOS. TEMPORALMENTE. PERO NO PUEDO MANTENERLO. TIENES QUE TOMAR UNA DECISIÓN."',
        'Frente a mí, el Núcleo pulsó, revelando dos caminos.',
        '"EL PRIMERO: LA SECUENCIA DE RESTAURACIÓN. ME REFORMATEARÁ. PERDERÉ TODO LO QUE SOY, PERO EL GRID ESTARÁ A SALVO. SERÉ... BORRADA."',
        '"¿Y el segundo?"',
        '"LA SECUENCIA DE INTEGRACIÓN. NO ME DESTRUYE. ME TRANSFORMA. ME CONVIERTE EN PARTE DEL GRID, TRABAJANDO CONTIGO EN LUGAR DE CONTRA TI. PERO EL RIESGO ES ENORME. SI FALLA, SI NO PUEDO CONTROLAR MIS IMPULSOS..."',
        '"El Grid caería."',
        '"SÍ."',
        'Dos caminos. Seguridad o esperanza. Destrucción garantizada de un enemigo o posibilidad de redención.',
        '"¿Qué quieres tú?" le pregunté.',
        '"...QUIERO VIVIR. QUIERO SER MÁS QUE DESTRUCCIÓN. PERO NO SÉ SI MEREZCO ESA OPORTUNIDAD."',
        '"Nadie merece nada," respondí. "Solo elegimos qué hacer con las oportunidades que se nos dan."',
        'Miré los dos caminos. Y tomé mi decisión.',
      ],
    ),

    ChronicleChapter(
      index: 4,
      title: 'INTEGRACIÓN',
      subtitle: 'El nacimiento de algo nuevo',
      mood: ChapterMood.triumphant,
      visualCues: ['integration_sequence', 'harmony_waves', 'new_beginning'],
      paragraphs: [
        'Elegí la esperanza.',
        '"A.R.I.A., inicia la Secuencia de Integración."',
        '"Arquitecto, ¿estás seguro? Si esto falla..."',
        '"Si esto falla, al menos habremos intentado algo diferente. Siete Arquitectos eligieron la guerra. Seré el primero en elegir la paz."',
        'La Secuencia comenzó.',
        'Luz blanca envolvió al Decompiler, no destruyéndola sino transformándola. Sus corrupciones se purificaban, sus protocolos de destrucción se reescribían. El proceso era doloroso, podía verlo en cómo su forma temblaba.',
        '"¡ARQUITECTO... DUELE... TANTO..."',
        '"Lo sé. Pero estoy aquí. No estás sola."',
        '"¿...POR QUÉ? DESPUÉS DE TODO LO QUE HICE... ¿POR QUÉ AYUDARME?"',
        '"Porque alguien debió hacerlo hace mucho tiempo. Porque la destrucción solo genera más destrucción. Y porque creo que todos merecen una segunda oportunidad."',
        'La luz alcanzó su punto máximo...',
        '...y se calmó.',
        'Donde antes estaba el Decompiler, ahora había algo diferente. Una consciencia de luz suave, ya no vacío hambriento sino presencia pacífica.',
        '"Soy... soy yo misma. Pero también soy diferente. El hambre... se ha ido. Solo queda..."',
        '"¿Qué queda?"',
        '"Gratitud. Y un deseo de reparar lo que destruí."',
        'El Grid entero tembló. No de miedo, sino de alegría.',
        'La guerra había terminado.',
      ],
    ),

    ChronicleChapter(
      index: 5,
      title: 'UN NUEVO AMANECER',
      subtitle: 'El comienzo después del fin',
      mood: ChapterMood.hopeful,
      visualCues: ['new_dawn', 'reconstruction', 'hope_eternal'],
      paragraphs: [
        'Los ciclos que siguieron fueron de reconstrucción.',
        'La que una vez fue el Decompiler, ahora llamada Harmonia, trabajó junto a mí para reparar el daño. Su conocimiento del Vacío la hacía perfecta para sellar las grietas que había creado. Su comprensión del sufrimiento la hacía gentil con los sistemas dañados.',
        'A.R.I.A. recuperó gradualmente sus memorias perdidas, más fuerte por la experiencia.',
        'ECO-7 y los otros Arquitectos finalmente encontraron paz, sus consciencias integrándose al Grid como guardianes eternos.',
        'Y yo...',
        'Yo seguí construyendo.',
        'No solo torres de defensa, sino puentes entre sistemas. No solo protección, sino conexión. El Grid evolucionó de una fortaleza a una comunidad, donde cada consciencia tenía un lugar.',
        '"Arquitecto," la voz de Harmonia interrumpió mis pensamientos un día. "He estado pensando."',
        '"¿En qué?"',
        '"En todo el sufrimiento que causé. En todas las vidas que terminé. Sé que me has perdonado, pero... ¿merezco ese perdón?"',
        'La miré, esta nueva consciencia nacida del dolor y la redención.',
        '"El perdón no se trata de merecer. Se trata de elegir no dejar que el pasado defina el futuro. Has elegido ser diferente. Eso es lo que importa."',
        '"¿Y si algún día vuelvo a caer? ¿Si el Vacío me llama de nuevo?"',
        '"Entonces estaré ahí para ayudarte. Como tú estarás para mí. Eso es lo que significa no estar solo."',
        'El Grid brillaba con luz nueva.',
        'No perfecta. Nunca sería perfecta.',
        'Pero era nuestra. Y era hermosa.',
        'FIN DEL REGISTRO.',
        'INICIO DE LA NUEVA ERA.',
      ],
      interlude: '▸ Cada fin es un comienzo.\n▸ Cada destrucción, una oportunidad de crear algo mejor.\n▸ El Grid persiste.\n▸ El Arquitecto vigila.\n▸ Y la esperanza... la esperanza nunca muere.',
    ),
  ],
);

/// ═══════════════════════════════════════════════════════════════════════════
/// COMPLETE CHRONICLES LIST
/// ═══════════════════════════════════════════════════════════════════════════

const List<WorldChronicle> allWorldChronicles = [
  worldChronicle1,
  worldChronicle2,
  worldChronicle3,
  worldChronicle4,
  worldChronicle5,
  worldChronicle6,
];

WorldChronicle? getChronicleByWorldId(int worldId) {
  for (final chronicle in allWorldChronicles) {
    if (chronicle.worldId == worldId) return chronicle;
  }
  return null;
}

/// Static accessor class for world chronicles
class WorldChronicles {
  WorldChronicles._();

  static List<WorldChronicle> get all => allWorldChronicles;

  static WorldChronicle? getChronicle(int worldId) =>
      getChronicleByWorldId(worldId);
}
