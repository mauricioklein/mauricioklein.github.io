interface Dictionary {
    [propName: string]: number;
}

const AVAILABLE_LETTERS: Dictionary = {
    'a': 8, 'b': 6, 'c': 6, 'd': 6,
    'e': 8, 'f': 4, 'g': 6, 'h': 6,
    'i': 8, 'j': 4, 'k': 6, 'l': 8,
    'm': 6, 'n': 6, 'o': 6, 'p': 6,
    'q': 2, 'r': 8, 's': 8, 't': 8,
    'u': 6, 'v': 4, 'w': 2, 'x': 4,
    'y': 4, 'z': 4, '&': 2, '!': 2,
    '?': 2, '#': 2, '@': 2
}

const calculate_missing = (phrases: string[], dictionary: Dictionary) => {
    const missing: Dictionary = {}

    // Discount from the dictionary the letters
    // used in the phrases
    for (const phrase of phrases) {
        phrase
            .toLowerCase()
            .split('')
            .filter(ch => ch in dictionary)
            .forEach(ch => {
                dictionary[ch]--

                if (dictionary[ch] < 0) {
                    missing[ch] = dictionary[ch]
                }
            })
    }

    return missing
}

const phraseA = document.getElementById('phrase-a')! as HTMLInputElement
const phraseB = document.getElementById('phrase-b')! as HTMLInputElement
const resultContainer = document.getElementById('result-container')! as HTMLDivElement

[phraseA, phraseB].forEach(elem => elem.addEventListener('input', () => {
    const dictionary = Object.assign({}, AVAILABLE_LETTERS)
    const phrases = [phraseA.value, phraseB.value]

    const missing = calculate_missing(phrases, dictionary)

    renderResponse(missing)
}))

const renderResponse = (missing: Dictionary) => {
    // Remove all children
    resultContainer.innerText = ''

    const successBox = infoBox('success-box')
    const errorBox = infoBox('error-box')

    if (Object.keys(missing).length == 0) {
        resultContainer.appendChild(successBox("OK!"))
    } else {
        resultContainer.append(
            ...Object
                .keys(missing)
                .map(key => errorBox(`Missing ${Math.abs(missing[key])} ${key}'s`))
        )
    }
}

const infoBox = (cssClass: 'success-box' | 'error-box') => (
    (text: string) => {
        const div = document.createElement('div') as HTMLDivElement
        div.classList.add(cssClass)
        div.innerHTML = `<b>${text}</b>`

        return div
    }
)
