<template>
  <div>
    <div class="error-box" v-for="(count, char) in missing" :key="char">
      <b>Missing {{ count }} {{ char }}'s</b>
    </div>
  </div>
</template>

<script>
  import Vue from 'vue'

  export default Vue.component('Error', {
    props: {
      missing: Object
    }
  })
</script>

<style scoped>
  .error-box {
    width: 50%;
    margin: 10px 0px;
    padding: 3px 0px 3px 0px;
    color: #D8000C;
    background-color: #FFD2D2;
  }
</style>
