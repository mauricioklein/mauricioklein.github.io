<template>
  <center>
    <input
      v-for="(phrase, index) in phrases"
      :key="index"
      v-model="phrases[index]"
      type="text"
      class="phrase"
    />

    <Result :missing="missing" />
  </center>
</template>

<script>
  import Vue from 'vue'
  import { Result } from  './components';

  export default Vue.component('App', {
    data: () => ({
      phrases: ["", ""],
      board: {
        'a': 8, 'b': 6, 'c': 6, 'd': 6,
        'e': 8, 'f': 4, 'g': 6, 'h': 6,
        'i': 8, 'j': 4, 'k': 6, 'l': 8,
        'm': 6, 'n': 6, 'o': 6, 'p': 6,
        'q': 2, 'r': 8, 's': 8, 't': 8,
        'u': 6, 'v': 4, 'w': 2, 'x': 4,
        'y': 4, 'z': 4, '&': 2, '!': 2,
        '?': 2, '#': 2, '@': 2
      }
    }),

    components: {
      Result
    },

    computed: {
      missing: function() {
        return this.calculate_missing(this.phrases, Object.assign({}, this.board))
      }
    },

    methods: {
      calculate_missing: (phrases, dictionary) => {
        const missing = {}

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
                missing[ch] = -dictionary[ch]
              }
            })
        }

        return missing
      }
    }
  });
</script>

<style scoped>
  * {
    font: inherit;
    color: inherit;
  }

  .phrase {
    width: 50%;
    padding: 8px 10px;
    margin: 8px;
    border: 1px solid #cccccc;
    box-sizing: border-box;
    font: inherit;
    color: inherit;
  }
</style>
