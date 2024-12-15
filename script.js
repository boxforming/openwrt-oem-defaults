/**
 * Helper function to get element by id
 * @param {string} id Element id
 * @returns {HTMLElement | undefined}
 */
function $(id) {
  const element = document.getElementById(id);
  if (!element) {
    console.error(`Element with ID '${id}' not found!`);
    return;
  }
  return element;
}

/**
 * Helper function to create new element
 * @param {string} tagName Tag name of new element
 * @param {Object} attrs Attributes
 * @param  {...any} children Child nodes
 * @returns {HTMLElement}
 */
function makeEl(tagName, attrs = {}, ...children) {
  const el = document.createElement(tagName);
  for (const [attr, value] of Object.entries(attrs)) {
    el.setAttribute(attr, value);
  }
  el.append(...children);
  return el;
}

/**
 * Helper function to copy element's inner text to clipboard
 * @param {HTMLElement} el Element to copy
 */
function copyToClipboard(el) {
  if (el.value) {
    // this is an input or textarea
    navigator.clipboard.writeText(el.value);
  } else {
    const range = document.createRange();
    range.selectNode(el);
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    navigator.clipboard.writeText(selection.toString());
    selection.removeAllRanges();
  }
}

const version = document.currentScript.src.split('?v=')[1];

function fetchJson(url) {
  return fetch(`${url}?v=${version}`).then(response => response.json());
}

function fetchText(url) {
  return fetch(`${url}?v=${version}`).then(response => response.text());
}

function fillModelSelect(data, modelSelect) {
  data.forEach(model => {
    const option = makeEl('option', { value: model }, model);
    modelSelect.appendChild(option);
  });
}

document.addEventListener('DOMContentLoaded', () => {
  /** @type {HTMLSelectElement} */
  const modelSelect    = $('modelSelect');
  /** @type {HTMLButtonElement} */
  const generateButton = $('generateButton');
  /** @type {HTMLPreElement} */
  const outputElement  = $('output');

  if (!modelSelect || !generateButton || !outputElement) {
    // TODO: add user message
    return; // Stop if any element is not found (error already logged by $)
  }

  generateButton.disabled = true;

  const modelsLoader = fetchJson(`models.json`);
  const headerLoader = fetchText(`chunks/header.sh`);
  const oemlibLoader = fetchText(`chunks/oemlib.sh`);
  const paramsLoader = fetchText(`chunks/params.sh`);
  const footerLoader = fetchText(`chunks/uci-defaults.sh`);

  let chunks = {};

  Promise.all(
    [modelsLoader, headerLoader, oemlibLoader, paramsLoader, footerLoader]
  ).then((
    [, header, oemlib, params, footer]
  ) => {
    chunks = {
      header,
      oemlib,
      params,
      footer
    };
    generateButton.disabled = false;
  }).catch(error => {
    // TODO: show error message to the user
    console.error('Error fetching chunks:', error);
  })

  modelsLoader.then(
    data => fillModelSelect(data, modelSelect)
  ).catch(error => {
    // TODO: show error message to the user
    console.error('Error fetching models:', error);
  });

  generateButton.addEventListener('click', () => {
    const selectedModel = modelSelect.value;

    fetchText(`parsers/${selectedModel}.sh`)
      .then(modelDataParser => {
        outputElement.textContent = [
          chunks.header,
          chunks.oemlib,
          chunks.params,
          modelDataParser,
          chunks.footer
        ].join("\n");
      })
      .catch(error => {
        console.error('Error generating content:', error);
        outputElement.textContent = 'Error: Failed to generate content.';
      });
  });
});

