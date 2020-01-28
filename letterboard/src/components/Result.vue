<template>
  <div>
    <Success v-if="noMissing" />
    <Error v-else :missing="missing" />
  </div>
</template>

<script>
  import Vue from 'vue'
  import { Success, Error } from '.'

  export default Vue.component('Result', {
    props: {
      missing: Object
    },

    components: {
      Success,
      Error
    },

    computed: {
      noMissing: function() {
        return Object.keys(this.missing).length == 0
      }
    }
  })
</script>
