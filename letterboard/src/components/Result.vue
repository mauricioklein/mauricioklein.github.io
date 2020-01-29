<template>
  <div>
    <Success v-if="noMissingLetter" />
    <Error v-else :missing="missing" />
  </div>
</template>

<script>
  import Vue from 'vue'
  import { Success, Error } from './status-box'

  export default Vue.component('Result', {
    props: {
      missing: Object
    },

    components: {
      Success,
      Error
    },

    computed: {
      noMissingLetter: function() {
        return Object.keys(this.missing).length == 0
      }
    }
  })
</script>

<style scoped>
  .success-box {
    width: 50%;
    margin: 10px 0px;
    padding: 3px 0px 3px 0px;
    color: #4F8A10;
    background-color: #DFF2BF;
  }
</style>
