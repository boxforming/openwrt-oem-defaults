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

  let parsedParams;

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

    parsedParams = parseConfigFile(params);

    const formFields = generateForm(parsedParams);

    for (const formField of formFields) {
      document.getElementById("params").appendChild(formField);
    }
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

    const params = generateConfigFile(new FormData($("params")), parsedParams);
    
    fetchText(`parsers/${selectedModel}.sh`)
      .then(modelDataParser => {
        outputElement.textContent = [
          chunks.header,
          chunks.oemlib,
          modelDataParser,
          "\nget_device_oem_data\n",
          params,
          chunks.footer
        ].join("\n");
      })
      .catch(error => {
        console.error('Error generating content:', error);
        outputElement.textContent = 'Error: Failed to generate content.';
      });
  });
});

/**
 * Parses a configuration file and extracts parameter definitions
 * @param {string} fileContent - The content of the configuration file
 * @returns {Object} Object with parameter definitions
 */
function parseConfigFile(fileContent) {
  const lines = fileContent.split('\n');
  const params = {};
  
  let i = 0;
  while (i < lines.length) {
    const line = lines[i].trim();
    
    // Check if this is a comment line with @type annotation
    if (line.startsWith('# @type')) {
      const commentMatch = line.match(/# @type \{([^}]+)\} \[?([^\]=\s]+)(?:=([^\]]+))?\]?(.*)/);
      
      if (commentMatch) {
        const [, typeStr, paramName, defaultValue, completeDescription] = commentMatch;
        const isOptional = line.includes(`[${paramName}`);
        const [description, link] = completeDescription.split(/(?=https:\/\/)/);
        
        // Parse the type
        let type;
        if (typeStr.includes('|')) {
          // It's a union type like 0|1
          const values = typeStr.split('|').map(v => {
            const trimmed = v.trim();
            return isNaN(trimmed) ? trimmed : Number(trimmed);
          });
          type = new Set(values);
        } else {
          type = typeStr.trim();
        }
        
        // Look for the actual parameter line (could be commented out)
        let value = undefined;
        let nextLine = i + 1;
        while (nextLine < lines.length) {
          const potentialParamLine = lines[nextLine].trim();
          if (potentialParamLine.startsWith('#')) {
            const uncommented = potentialParamLine.substring(1).trim();
            if (uncommented.startsWith(`${paramName}=`)) {
              // It's commented out, no value
              break;
            }
          } else if (potentialParamLine.startsWith(`${paramName}=`)) {
            // Found the actual value
            const valueMatch = potentialParamLine.match(/=\s*"?([^"]+)"?/);
            if (valueMatch) {
              const rawValue = valueMatch[1];
              // Convert to appropriate type
              if (type instanceof Set) {
                value = isNaN(rawValue) ? rawValue : Number(rawValue);
              } else if (type === 'string') {
                value = rawValue;
              } else {
                value = rawValue;
              }
            }
            break;
          } else if (potentialParamLine === '' || potentialParamLine.startsWith('#')) {
            nextLine++;
            continue;
          } else {
            break;
          }
          nextLine++;
        }
        
        params[paramName] = {
          value: value,
          type: type,
          required: !isOptional,
          default: defaultValue ? (isNaN(defaultValue) ? defaultValue : Number(defaultValue)) : undefined,
          description: description.trim(),
          link,
        };
      }
    }
    i++;
  }
  
  return params;
}

/**
 * Generates a configuration file from FormData and parameter definitions
 * @param {FormData} formData - The form data containing parameter values
 * @param {Object} paramDefinitions - Parameter definitions from parseConfigFile
 * @returns {string} Generated configuration file content
 */
function generateConfigFile(formData, paramDefinitions) {
  const lines = [];
  
  for (const [paramName, paramDef] of Object.entries(paramDefinitions)) {
    // Build the type annotation
    let typeStr;
    if (paramDef.type instanceof Set) {
      typeStr = Array.from(paramDef.type).join('|');
    } else {
      typeStr = paramDef.type;
    }
    
    // Build the parameter name with optional brackets and default
    let paramHeader = paramName;
    if (!paramDef.required) {
      paramHeader = `[${paramName}`;
      if (paramDef.default !== undefined) {
        paramHeader += `=${paramDef.default}`;
      }
      paramHeader += `]`;
    }
    
    // Add the comment line
    const commentLine = `# @type {${typeStr}} ${paramHeader} ${paramDef.description}`;
    lines.push(commentLine);
    
    // Get value from FormData
    const formValue = formData.get(paramName);
    
    // Determine if we should write the parameter line
    if (formValue !== null && formValue !== undefined && formValue !== '') {
      let finalValue = formValue;
      
      // Validate against type if it's a Set
      if (paramDef.type instanceof Set) {
        const numValue = isNaN(formValue) ? formValue : Number(formValue);
        if (!paramDef.type.has(numValue)) {
          console.warn(`Warning: ${paramName} value "${formValue}" not in allowed set`);
        }
        finalValue = numValue;
      }
      
      lines.push(`${paramName}="${finalValue}"`);
    } else if (paramDef.required && paramDef.value !== undefined) {
      // Required parameter with existing value
      lines.push(`${paramName}="${paramDef.value}"`);
    } else {
      // Optional parameter, comment it out
      const defaultVal = paramDef.default !== undefined ? paramDef.default : 
                        (paramDef.value !== undefined ? paramDef.value : '');
      lines.push(`# ${paramName}="${defaultVal}"`);
    }
    
    lines.push(''); // Empty line between parameters
  }
  
  return lines.join('\n');
}

/**
 * Generates an HTML form from parsed configuration parameters
 * @param {Object} params - Parameters object from parseConfigFile
 * @param {Object} options - Optional configuration for form generation
 * @returns {HTMLDivElement} Generated form element
 */
function generateForm(params, options = {}) {
  const formGroups = [];
  
  for (const [paramName, paramDef] of Object.entries(params)) {
    const fieldId = `field_${paramName}`;
    
    // Create label
    const labelText = paramDef.description;
    const requiredMark = paramDef.required ? makeEl('span', { class: 'required' }, ' *') : '';
    const label = makeEl('label', { for: fieldId }, labelText, requiredMark);
    
    // Create input based on type
    let input;
    
    if (paramDef.type instanceof Set) {
      // Create select dropdown for union types
      const options = Array.from(paramDef.type).map(val => {
        const isSelected = paramDef.value !== undefined ? 
          paramDef.value == val : 
          (paramDef.default !== undefined && paramDef.default == val);
        
        return makeEl('option', 
          { value: val, ...(isSelected && { selected: 'selected' }) }, 
          String(val)
        );
      });
      
      // Add empty option for optional fields
      if (!paramDef.required) {
        options.unshift(makeEl('option', { value: '' }, '-- Not set --'));
      }
      
      input = makeEl('select', 
        { 
          id: fieldId, 
          name: paramName,
          ...(paramDef.required && { required: 'required' })
        }, 
        ...options
      );
    } else {
      // Create text input for string types
      const currentValue = paramDef.value !== undefined ? 
        paramDef.value : 
        (paramDef.default !== undefined ? paramDef.default : '');
      
      input = makeEl('input', {
        type: 'text',
        id: fieldId,
        name: paramName,
        value: currentValue,
        placeholder: paramDef.default !== undefined ? `Default: ${paramDef.default}` : '',
        ...(paramDef.required && { required: 'required' })
      });
    }
    
    // Create description/help text
    // const description = makeEl('small', { class: 'help-text' }, paramDef.description);
    
    // Create form group
    const formGroup = makeEl('div', { class: 'form-group' }, label, input);
    formGroups.push(formGroup);
  }
  
  return formGroups;
}

if (typeof module !== "undefined") {
  module.exports = {
    parseConfigFile
  }
}
