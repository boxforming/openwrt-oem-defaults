function $(id) {
  const element = document.getElementById(id);
  if (!element) {
    console.error(`Element with ID '${id}' not found!`);
  }
  return element;
}

function makeEl(tagName, attributes = {}, ...children) {
  const element = document.createElement(tagName);
  for (const [attr, value] of Object.entries(attributes)) {
    element.setAttribute(attr, value);
  }
  element.append(...children);
  return element;
}

document.addEventListener('DOMContentLoaded', () => {
  const modelSelect = $('modelSelect');
  const generateButton = $('generateButton');
  const outputElement = $('output');

  if (!modelSelect || !generateButton || !outputElement) {
    return; // Stop if any element is not found (error already logged by $)
  }

  fetch('models.json')
    .then(response => response.json())
    .then(data => {
      data.forEach(model => {
        const option = makeEl('option', { value: model }, model);
        modelSelect.appendChild(option);
      });
    })
    .catch(error => {
      console.error('Error fetching models:', error);
    });

  generateButton.addEventListener('click', () => {
    const selectedModel = modelSelect.value;

    fetch(`parsers/${selectedModel}.sh`)
      .then(response => response.text())
      .then(generatedContent => {
        outputElement.textContent = generatedContent;
      })
      .catch(error => {
        console.error('Error generating content:', error);
        outputElement.textContent = 'Error: Failed to generate content.';
      });
  });
});

