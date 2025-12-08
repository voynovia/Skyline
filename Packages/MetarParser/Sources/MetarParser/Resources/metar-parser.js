// METAR/TAF Parser for JavaScriptCore

(function(global) {
  'use strict';

  function parseMetar(raw) {
    if (!raw || typeof raw !== 'string') {
      return null;
    }

    var metar = raw.trim().toUpperCase();
    var result = {
      raw: raw.trim(),
      station: '',
      rawTimestamp: null,
      isCorrection: false,
      isAuto: false,
      windDirection: null,
      isWindVariable: false,
      windSpeedKt: null,
      windGustKt: null,
      visibilityMeters: null,
      visibilityMiles: null,
      isCavok: false,
      clouds: [],
      temperatureC: null,
      dewpointC: null,
      altimeterHpa: null,
      altimeterInHg: null,
      weather: [],
      remarks: null
    };

    // remove METAR/SPECI prefix
    metar = metar.replace(/^(METAR|SPECI)\s+/, '');

    // station (4 letters)
    var stationMatch = metar.match(/^([A-Z]{4})\s+/);
    if (stationMatch) {
      result.station = stationMatch[1];
      metar = metar.substring(stationMatch[0].length);
    }

    // time (DDHHMMz)
    var timeMatch = metar.match(/^(\d{2})(\d{2})(\d{2})Z\s+/);
    if (timeMatch) {
      result.rawTimestamp = timeMatch[1] + timeMatch[2] + timeMatch[3] + 'Z';
      metar = metar.substring(timeMatch[0].length);
    }

    // AUTO
    if (/^AUTO\s+/.test(metar)) {
      result.isAuto = true;
      metar = metar.replace(/^AUTO\s+/, '');
    }

    // COR
    if (/^COR\s+/.test(metar)) {
      result.isCorrection = true;
      metar = metar.replace(/^COR\s+/, '');
    }

    // wind
    var windMatch = metar.match(/^(VRB|\d{3})(\d{2,3})(G(\d{2,3}))?(KT|MPS)\s+/);
    if (windMatch) {
      if (windMatch[1] === 'VRB') {
        result.isWindVariable = true;
      } else {
        result.windDirection = parseInt(windMatch[1], 10);
      }
      var speed = parseInt(windMatch[2], 10);
      if (windMatch[5] === 'MPS') {
        speed = Math.round(speed * 1.944);
      }
      result.windSpeedKt = speed;
      if (windMatch[4]) {
        var gust = parseInt(windMatch[4], 10);
        if (windMatch[5] === 'MPS') {
          gust = Math.round(gust * 1.944);
        }
        result.windGustKt = gust;
      }
      metar = metar.substring(windMatch[0].length);
    }

    // variable wind direction
    var windVarMatch = metar.match(/^(\d{3})V(\d{3})\s+/);
    if (windVarMatch) {
      metar = metar.substring(windVarMatch[0].length);
    }

    // CAVOK
    if (/^CAVOK\s+/.test(metar)) {
      result.isCavok = true;
      result.visibilityMeters = 10000;
      metar = metar.replace(/^CAVOK\s+/, '');
    } else {
      // visibility in meters (4 digits)
      var visMatch = metar.match(/^(\d{4})\s+/);
      if (visMatch) {
        result.visibilityMeters = parseInt(visMatch[1], 10);
        metar = metar.substring(visMatch[0].length);
      }

      // visibility in statute miles
      var visMiMatch = metar.match(/^(M)?(\d+)?\/?(\d+)?SM\s+/);
      if (visMiMatch) {
        var vis = 0;
        if (visMiMatch[2] && visMiMatch[3]) {
          vis = parseInt(visMiMatch[2], 10) / parseInt(visMiMatch[3], 10);
        } else if (visMiMatch[2]) {
          vis = parseInt(visMiMatch[2], 10);
        }
        if (visMiMatch[1] === 'M') vis = vis - 0.01;
        result.visibilityMiles = vis;
        metar = metar.substring(visMiMatch[0].length);
      }
    }

    // weather phenomena
    var wxRegex = /^([-+]|VC)?(MI|PR|BC|DR|BL|SH|TS|FZ)?(DZ|RA|SN|SG|IC|PL|GR|GS|UP|BR|FG|FU|VA|DU|SA|HZ|PY|PO|SQ|FC|SS|DS)+\s+/;
    var wxMatch;
    while ((wxMatch = metar.match(wxRegex)) !== null) {
      var wx = {
        intensity: wxMatch[1] || '',
        descriptor: wxMatch[2] || null,
        phenomenon: wxMatch[0].trim().replace(/^[-+]|^VC/, '').replace(/^(MI|PR|BC|DR|BL|SH|TS|FZ)/, ''),
        raw: wxMatch[0].trim()
      };
      result.weather.push(wx);
      metar = metar.substring(wxMatch[0].length);
    }

    // clouds
    var cloudRegex = /^(FEW|SCT|BKN|OVC|VV|CLR|SKC|NSC|NCD)(\d{3})?(CB|TCU)?\s+/;
    var cloudMatch;
    while ((cloudMatch = metar.match(cloudRegex)) !== null) {
      var cloud = {
        coverage: cloudMatch[1],
        heightFeet: cloudMatch[2] ? parseInt(cloudMatch[2], 10) * 100 : null,
        cloudType: cloudMatch[3] || null
      };
      result.clouds.push(cloud);
      metar = metar.substring(cloudMatch[0].length);
    }

    // temperature and dewpoint
    var tempMatch = metar.match(/^(M)?(\d{2})\/(M)?(\d{2})\s+/);
    if (tempMatch) {
      result.temperatureC = parseInt(tempMatch[2], 10) * (tempMatch[1] === 'M' ? -1 : 1);
      result.dewpointC = parseInt(tempMatch[4], 10) * (tempMatch[3] === 'M' ? -1 : 1);
      metar = metar.substring(tempMatch[0].length);
    }

    // QNH (hectopascals)
    var qnhMatch = metar.match(/^Q(\d{4})\s*/);
    if (qnhMatch) {
      result.altimeterHpa = parseInt(qnhMatch[1], 10);
      metar = metar.substring(qnhMatch[0].length);
    }

    // altimeter (inches)
    var altMatch = metar.match(/^A(\d{4})\s*/);
    if (altMatch) {
      result.altimeterInHg = parseInt(altMatch[1], 10) / 100;
      metar = metar.substring(altMatch[0].length);
    }

    // remarks
    var rmkMatch = metar.match(/^RMK\s+(.*)$/);
    if (rmkMatch) {
      result.remarks = rmkMatch[1].trim();
    }

    return result;
  }

  function parseTaf(raw) {
    if (!raw || typeof raw !== 'string') {
      return null;
    }

    var taf = raw.trim().toUpperCase();
    var result = {
      raw: raw.trim(),
      station: '',
      rawIssueTime: null,
      rawValidFrom: null,
      rawValidTo: null,
      isAmended: false,
      isCorrected: false,
      forecast: {
        windDirection: null,
        isWindVariable: false,
        windSpeedKt: null,
        windGustKt: null,
        visibilityMeters: null,
        isCavok: false,
        clouds: [],
        weather: []
      },
      changes: []
    };

    // AMD/COR
    result.isAmended = /\bAMD\b/.test(taf);
    result.isCorrected = /\bCOR\b/.test(taf);

    // remove TAF AMD COR prefix
    taf = taf.replace(/^TAF\s+(AMD\s+)?(COR\s+)?/, '');

    // station
    var stationMatch = taf.match(/^([A-Z]{4})\s+/);
    if (stationMatch) {
      result.station = stationMatch[1];
      taf = taf.substring(stationMatch[0].length);
    }

    // issue time
    var issueMatch = taf.match(/^(\d{6})Z\s+/);
    if (issueMatch) {
      result.rawIssueTime = issueMatch[1] + 'Z';
      taf = taf.substring(issueMatch[0].length);
    }

    // validity period
    var validMatch = taf.match(/^(\d{4})\/(\d{4})\s+/);
    if (validMatch) {
      result.rawValidFrom = validMatch[1];
      result.rawValidTo = validMatch[2];
      taf = taf.substring(validMatch[0].length);
    }

    // parse base forecast wind
    var windMatch = taf.match(/^(VRB|\d{3})(\d{2,3})(G(\d{2,3}))?KT\s+/);
    if (windMatch) {
      if (windMatch[1] === 'VRB') {
        result.forecast.isWindVariable = true;
      } else {
        result.forecast.windDirection = parseInt(windMatch[1], 10);
      }
      result.forecast.windSpeedKt = parseInt(windMatch[2], 10);
      if (windMatch[4]) {
        result.forecast.windGustKt = parseInt(windMatch[4], 10);
      }
      taf = taf.substring(windMatch[0].length);
    }

    // CAVOK
    if (/^CAVOK\s+/.test(taf)) {
      result.forecast.isCavok = true;
      result.forecast.visibilityMeters = 10000;
      taf = taf.replace(/^CAVOK\s+/, '');
    } else {
      // visibility
      var visMatch = taf.match(/^(\d{4})\s+/);
      if (visMatch) {
        result.forecast.visibilityMeters = parseInt(visMatch[1], 10);
        taf = taf.substring(visMatch[0].length);
      }
    }

    // clouds in base forecast
    var cloudRegex = /^(FEW|SCT|BKN|OVC|VV|CLR|SKC|NSC|NCD)(\d{3})?(CB|TCU)?\s+/;
    var cloudMatch;
    while ((cloudMatch = taf.match(cloudRegex)) !== null) {
      var cloud = {
        coverage: cloudMatch[1],
        heightFeet: cloudMatch[2] ? parseInt(cloudMatch[2], 10) * 100 : null,
        cloudType: cloudMatch[3] || null
      };
      result.forecast.clouds.push(cloud);
      taf = taf.substring(cloudMatch[0].length);
    }

    return result;
  }

  function parseMetars(rawArray) {
    if (!Array.isArray(rawArray)) return [];
    return rawArray.map(function(raw) {
      try {
        return { success: true, data: parseMetar(raw) };
      } catch (e) {
        return { success: false, error: String(e), raw: raw };
      }
    });
  }

  function parseTafs(rawArray) {
    if (!Array.isArray(rawArray)) return [];
    return rawArray.map(function(raw) {
      try {
        return { success: true, data: parseTaf(raw) };
      } catch (e) {
        return { success: false, error: String(e), raw: raw };
      }
    });
  }

  global.parseMetar = parseMetar;
  global.parseTaf = parseTaf;
  global.parseMetars = parseMetars;
  global.parseTafs = parseTafs;

})(this);
