document.addEventListener("DOMContentLoaded", () => {

  // получаем базовый URL из текущей страницы
  const baseURL = window.location.origin;

  // единый стиль base.json (без topo слоёв)
  const styleFile = 'base.json';

  // определяем тему из URL параметра (передаётся из Swift)
  const urlParams = new URLSearchParams(window.location.search);
  const theme = urlParams.get('theme') || 'light';
  const isDarkMode = theme === 'dark';

  // обновляем фон контейнера в зависимости от темы
  document.getElementById('map').style.background = isDarkMode ? '#1A1A1A' : '#E8E4E0';

  console.log(`Theme: ${theme}, isDarkMode: ${isDarkMode}`);

  // регистрируем протокол pmtiles
  const protocol = new pmtiles.Protocol();
  maplibregl.addProtocol('pmtiles', protocol.tile);

  const map = new maplibregl.Map({
    container: 'map',
    style: `${baseURL}/${styleFile}`,
    zoom: 3,
    minZoom: 3,
    maxZoom: 18,
    attributionControl: false,
    renderWorldCopies: false,
    maxTileCacheSize: 50,
    fadeDuration: 0
  });

  // API для вызова из Swift
  window.mapAPI = {
    // добавление источника
    addSource: (id, config) => {
      try {
        if (map.getSource(id)) {
          console.log(`Источник ${id} уже существует`);
          return;
        }
        map.addSource(id, config);
        console.log(`Источник ${id} добавлен`);
      } catch (error) {
        console.error(`Ошибка добавления источника ${id}:`, error);
      }
    },

    // удаление источника (и связанных слоёв)
    removeSource: (id) => {
      try {
        const layers = map.getStyle().layers || [];
        for (const layer of layers.filter(l => l.source === id)) {
          if (map.getLayer(layer.id)) {
            map.removeLayer(layer.id);
          }
        }
        if (map.getSource(id)) {
          map.removeSource(id);
        }
      } catch (error) {
        console.error(`Ошибка удаления источника ${id}:`, error);
      }
    },

    // добавление слоя
    addLayer: (config, beforeId) => {
      try {
        if (map.getLayer(config.id)) {
          console.log(`Слой ${config.id} уже существует`);
          return;
        }
        if (beforeId) {
          map.addLayer(config, beforeId);
        } else {
          map.addLayer(config);
        }
        console.log(`Слой ${config.id} добавлен`);
      } catch (error) {
        console.error(`Ошибка добавления слоя ${config.id}:`, error);
      }
    },

    // добавление слоёв из URL
    addLayerFromURL: async (url) => {
      try {
        const response = await fetch(url);
        const layers = await response.json();

        for (const layerConfig of layers) {
          // автоматически добавляем источник если нужен и его нет
          if (layerConfig.source && !map.getSource(layerConfig.source)) {
            // определяем тип источника
            const sourceType = layerConfig.type === 'raster' ? 'raster' : 'vector';
            map.addSource(layerConfig.source, {
              type: sourceType,
              tiles: [`${baseURL}/tiles/${layerConfig.source}/{z}/{x}/{y}.pbf`]
            });
            console.log(`Источник ${layerConfig.source} добавлен автоматически`);
          }

          if (!map.getLayer(layerConfig.id)) {
            const beforeId = layerConfig.insertAfterId || undefined;
            if (beforeId && map.getLayer(beforeId)) {
              map.addLayer(layerConfig, beforeId);
            } else {
              map.addLayer(layerConfig);
            }
            console.log(`Слой ${layerConfig.id} добавлен`);
          }
        }
      } catch (error) {
        console.error(`Ошибка загрузки слоёв из ${url}:`, error);
      }
    },

    // добавление слоёв из inline конфигурации
    addLayersInline: (configs) => {
      try {
        for (const config of configs) {
          // автоматически добавляем source если не существует
          if (config.source && !map.getSource(config.source)) {
            const sourceType = config.type === 'raster' ? 'raster' : 'vector';
            map.addSource(config.source, {
              type: sourceType,
              tiles: [`${baseURL}/tiles/${config.source}/{z}/{x}/{y}.pbf`]
            });
            console.log(`Источник ${config.source} добавлен автоматически`);
          }
          // добавляем слой
          if (!map.getLayer(config.id)) {
            map.addLayer(config);
            console.log(`Слой ${config.id} добавлен`);
          }
        }
      } catch (error) {
        console.error('Ошибка добавления слоёв:', error);
      }
    },

    // удаление слоя
    removeLayer: (id) => {
      try {
        if (map.getLayer(id)) {
          map.removeLayer(id);
          console.log(`Слой ${id} удалён`);
        }
      } catch (error) {
        console.error(`Ошибка удаления слоя ${id}:`, error);
      }
    },

    // полное отключение source (удаляет все слои + source)
    disableSource: (sourceId) => {
      try {
        const layers = map.getStyle().layers || [];
        const layersToRemove = layers.filter(l => l.source === sourceId);
        for (const layer of layersToRemove) {
          if (map.getLayer(layer.id)) {
            map.removeLayer(layer.id);
          }
        }
        if (map.getSource(sourceId)) {
          map.removeSource(sourceId);
        }
      } catch (error) {
        console.error(`Ошибка отключения source ${sourceId}:`, error);
      }
    },

    // включение source и слоёв
    enableSource: (sourceId, sourceConfig, layerConfigs) => {
      try {
        if (!map.getSource(sourceId)) {
          map.addSource(sourceId, sourceConfig);
        }
        for (const config of layerConfigs) {
          if (!map.getLayer(config.id)) {
            map.addLayer(config);
          }
        }
      } catch (error) {
        console.error(`Ошибка включения source ${sourceId}:`, error);
      }
    },

    // установка центра карты
    setCenter: (lng, lat) => {
      map.setCenter([lng, lat]);
    },

    // установка зума
    setZoom: (zoom) => {
      map.setZoom(zoom);
    },

    // переход к позиции
    flyTo: (lng, lat, zoom) => {
      map.flyTo({ center: [lng, lat], zoom: zoom || map.getZoom() });
    },

    // получение текущего зума
    getZoom: () => map.getZoom(),

    // получение центра
    getCenter: () => map.getCenter()
  };

  // отправка событий в Swift с throttle (200ms)
  let lastMoveTime = 0;
  map.on('move', () => {
    const now = Date.now();
    if (now - lastMoveTime < 200) return;
    lastMoveTime = now;
    try {
      window.webkit.messageHandlers.zoom.postMessage(map.getZoom().toFixed(2));
    } catch (e) {}
  });

  map.on('load', async () => {
    console.log("Map loaded successfully");

    map.setProjection({ type: 'globe' });

    // обновляем цвет фона в зависимости от темы
    const bgColor = isDarkMode ? '#1E2528' : '#D0D8DC';
    map.setPaintProperty('background', 'background-color', bgColor);

    try {
      window.webkit.messageHandlers.zoom.postMessage(map.getZoom().toFixed(2));
    } catch (e) {}

    // обработка кликов
    map.on('click', async (e) => {
      const coordinates = e.lngLat;
      const features = map.queryRenderedFeatures(e.point);
      const layers = features.map(feature => ({
        layer: feature.layer.id,
        source: feature.source,
        sourceLayer: feature.sourceLayer || null,
        properties: feature.properties || {}
      }));

      try {
        window.webkit.messageHandlers.click.postMessage({
          longitude: coordinates.lng,
          latitude: coordinates.lat,
          layers: layers
        });
      } catch (e) {}
    });

    // загружаем изображение аэропорта если есть
    try {
      const image = await map.loadImage(`${baseURL}/assets/airport.png`);
      map.addImage('airport', image.data);
    } catch (e) {
      console.log('Изображение airport.png не найдено');
    }
  });

  // геолокация (опционально)
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords;
        console.log(`Geolocation: ${latitude}, ${longitude}`);
        map.setCenter([longitude, latitude]);
      },
      (error) => {
        console.log("Geolocation недоступна:", error.message);
      }
    );
  }

  // legacy: поддержка postMessage для обратной совместимости
  window.addEventListener("message", (event) => {
    if (typeof event.data !== "string") return;
    const parts = event.data.split(":");
    if (parts.length < 2) return;

    const command = parts[0];
    const value = parts.slice(1).join(":");

    switch (command) {
      case "addLayer":
        window.mapAPI.addLayerFromURL(value);
        break;
      case "removeLayer":
        window.mapAPI.removeSource(value);
        break;
    }
  });

});
