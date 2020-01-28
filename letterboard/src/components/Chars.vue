<template>
  <div>
    <button @click="toggleTable">Toggle Chars Table</button>
    <v-data-table :headers="headers" :items="items" v-show="tableVisible">
      <template v-slot:item.count="{ item }">
        <v-text-field
          key="item.char"
          type="number"
          min=0
          v-model="dictionary[item.char]"
        />
      </template>
    </v-data-table>
  </div>
</template>

<script>
  import Vue from 'vue'

  export default Vue.component('Chars', {
    props: {
      dictionary: Object
    },

    data: () => ({
      tableVisible: false,
      rules: {
        positive: value => value >= 0
      },
      headers: [
        {
          text: 'Character',
          value: 'char'
        },
        {
          text: 'Count',
          value: 'count'
        }
      ]
    }),

    computed: {
      items: function() {
        return Object.keys(this.dictionary).map(k => ({
          char: k,
          count: this.dictionary[k]
        }))
      }
    },

    methods: {
      toggleTable: function() {
        this.tableVisible = !this.tableVisible
      }
    }
  })
</script>

<style scoped>
  table,
  th,
  td {
    border: 1px solid black;
  }

  .center-cell {
    text-align: center;
  }
</style>
