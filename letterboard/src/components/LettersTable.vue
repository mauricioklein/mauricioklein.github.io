<template>
  <div class="chars-wrapper">
    <button class="toggle" @click="toggleTable">Toggle Letters Table</button>
    <div class="chars-table" v-show="tableVisible">
      <table align="center">
        <thead>
          <tr>
            <th>Letter</th>
            <th>Count</th>
          </tr>
        </thead>

        <tbody>
          <tr v-for="(count, letter) in table" :key="letter">
            <td>
              <b>{{letter}}</b>
            </td>
            <td>
              <input type="number" min="0" :value="count" @blur="sanitizeInput($event, letter)" />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
  import Vue from 'vue'

  export default Vue.component('LettersTable', {
    props: {
      table: Object
    },

    data: () => ({
      tableVisible: false,
    }),

    methods: {
      toggleTable: function() {
        this.tableVisible = !this.tableVisible
      },
      sanitizeInput: function(e, letter) {
        const value = e.target.value || 0
        this.table[letter] = Math.max(value, 0)
      }
    }
  })
</script>

<style scoped>
  th, td {
    width: 50%;
    padding: 5px;
    text-align: center;
    border-bottom: 1px solid #ddd;
  }

  td > input {
    width: 50%;
    border: none;
    text-align: center;
  }

  input[type=number]::-webkit-outer-spin-button,
  input[type=number]::-webkit-inner-spin-button {
    -webkit-appearance: none;
    -moz-appearance: none;
    appearance: none;
    margin: 0;
  }

  tr:hover {
    background-color: #f5f5f5;
  }

  .chars-wrapper {
    margin: 10px 0;
  }

  .chars-table {
    max-height: 200px;
    overflow-y: scroll;
  }

  .toggle {
    background-color: #2fa534d4;
    border: none;
    color: white;
    padding: 15px 40px;
    text-align: center;
    text-decoration: none;
    display: inline-block;
    font-size: 14px;
    margin-bottom: 10px;
    width: 50%;
    outline: none;
  }
</style>
