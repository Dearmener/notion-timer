<template>
  <div class="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-gray-900 to-gray-800 p-6">
    <div class="current-time">{{ currentTime }}</div>
    <div class="content w-full max-w-4xl">
      <h1 class="text-6xl font-bold mb-10 text-white text-center bg-clip-text text-transparent bg-gradient-to-r from-blue-400 to-purple-500">Notion Timer</h1>
      <div class="mb-8 flex justify-center items-center space-x-6">
        <button @click="showAddCountdownModal = true" class="notion-button text-lg py-3 px-6">
          Add Countdown
        </button>
        <button @click="addTimer('countup')" class="notion-button text-lg py-3 px-6">
          Add Count-up
        </button>
      </div>
      <div v-for="(timer, index) in timers" :key="index" class="timer-card mb-8 notion-card relative overflow-hidden">
        <div class="progress-bar" v-if="timer.type === 'countdown'" :style="{ width: `${getProgress(timer)}%` }"></div>
        <div class="flex justify-between items-center mb-6">
          <input v-model="timer.note" @change="saveTimers" placeholder="Add note" class="notion-input text-lg">
          <button @click="removeTimer(index)" class="remove-button">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        <div class="text-7xl font-bold mb-6 font-mono text-center text-white">
          {{ formatTime(timer.timeLeft) }}
        </div>
        <div class="flex space-x-4 justify-center">
          <button @click="startTimer(index)" class="notion-control-button text-lg py-2 px-5" :class="{ 'active': timer.isRunning }">
            Start
          </button>
          <button @click="pauseTimer(index)" class="notion-control-button text-lg py-2 px-5">
            Pause
          </button>
          <button @click="resetTimer(index)" class="notion-control-button text-lg py-2 px-5">
            Reset
          </button>
        </div>
      </div>
    </div>

    <!-- Add Countdown Modal -->
    <div v-if="showAddCountdownModal" class="modal-overlay">
      <div class="modal-content notion-card">
        <h2 class="text-3xl font-bold mb-6 text-white">Add Countdown</h2>
        <div class="mb-6">
          <label class="block text-white mb-2 text-lg">Time (minutes)</label>
          <input v-model="customCountdownMinutes" type="number" min="1" class="notion-input text-lg w-full">
        </div>
        <div class="flex justify-end space-x-4">
          <button @click="addCustomCountdown" class="notion-button text-lg py-2 px-5">
            Add
          </button>
          <button @click="showAddCountdownModal = false" class="notion-button notion-button-secondary text-lg py-2 px-5">
            Cancel
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted } from 'vue';

export default {
  setup() {
    const timers = ref([]);
    const showAddCountdownModal = ref(false);
    const customCountdownMinutes = ref(5);
    const currentTime = ref('');

    const updateCurrentTime = () => {
      const now = new Date();
      currentTime.value = now.toLocaleTimeString();
    };

    const formatTime = (seconds) => {
      const hours = Math.floor(seconds / 3600);
      const minutes = Math.floor((seconds % 3600) / 60);
      const remainingSeconds = seconds % 60;
      return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
    };

    const addTimer = (type) => {
      timers.value.push({
        type,
        timeLeft: type === 'countdown' ? customCountdownMinutes.value * 60 : 0,
        initialTime: type === 'countdown' ? customCountdownMinutes.value * 60 : 0,
        isRunning: false,
        note: '',
        interval: null,
      });
      saveTimers();
    };

    const addCustomCountdown = () => {
      addTimer('countdown');
      showAddCountdownModal.value = false;
      customCountdownMinutes.value = 5;
    };

    const removeTimer = (index) => {
      clearInterval(timers.value[index].interval);
      timers.value.splice(index, 1);
      saveTimers();
    };

    const startTimer = (index) => {
      const timer = timers.value[index];
      if (!timer.isRunning) {
        timer.isRunning = true;
        timer.interval = setInterval(() => {
          if (timer.type === 'countdown') {
            timer.timeLeft--;
            if (timer.timeLeft <= 0) {
              clearInterval(timer.interval);
              timer.isRunning = false;
              showNotification(timer.note || 'Countdown finished!');
            }
          } else {
            timer.timeLeft++;
          }
          saveTimers();
        }, 1000);
      }
    };

    const pauseTimer = (index) => {
      const timer = timers.value[index];
      if (timer.isRunning) {
        clearInterval(timer.interval);
        timer.isRunning = false;
        saveTimers();
      }
    };

    const resetTimer = (index) => {
      const timer = timers.value[index];
      clearInterval(timer.interval);
      timer.isRunning = false;
      timer.timeLeft = timer.initialTime;
      saveTimers();
    };

    const saveTimers = () => {
      localStorage.setItem('timers', JSON.stringify(timers.value.map(t => ({
        type: t.type,
        timeLeft: t.timeLeft,
        initialTime: t.initialTime,
        note: t.note,
      }))));
    };

    const loadTimers = () => {
      const savedTimers = JSON.parse(localStorage.getItem('timers') || '[]');
      timers.value = savedTimers.map(t => ({
        ...t,
        isRunning: false,
        interval: null,
      }));
    };

    const showNotification = (message) => {
      if ('Notification' in window) {
        Notification.requestPermission().then(permission => {
          if (permission === 'granted') {
          console.log(
            "Notification granted",message
           )
            new Notification('Timer Notification', { body: message });
          }
        });
      }
    };

    const getProgress = (timer) => {
      if (timer.type !== 'countdown') return 0;
      return ((timer.initialTime - timer.timeLeft) / timer.initialTime) * 100;
    };

    onMounted(() => {
      loadTimers();
      updateCurrentTime();
      setInterval(updateCurrentTime, 1000);
    });

    onUnmounted(() => {
      timers.value.forEach(timer => clearInterval(timer.interval));
    });

    return {
      timers,
      showAddCountdownModal,
      customCountdownMinutes,
      currentTime,
      formatTime,
      addTimer,
      addCustomCountdown,
      removeTimer,
      startTimer,
      pauseTimer,
      resetTimer,
      saveTimers,
      getProgress,
    };
  },
};
</script>

<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

body {
  font-family: 'Inter', sans-serif;
  background-color: #2f3437;
  color: #ffffff;
}

.notion-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background-color: #ffffff;
  color: #2f3437;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.notion-button:hover {
  background-color: #e0e0e0;
  transform: translateY(-2px);
  box-shadow: 0 6px 8px rgba(0, 0, 0, 0.15);
}

.notion-button-secondary {
  background-color: transparent;
  border: 2px solid #ffffff;
  color: #ffffff;
}

.notion-button-secondary:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.notion-card {
  background-color: rgba(55, 53, 47, 0.8);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 32px;
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
  backdrop-filter: blur(10px);
  transition: all 0.3s ease;
}

.notion-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px rgba(0, 0, 0, 0.3);
}

.notion-input {
  width: 100%;
  padding: 12px 16px;
  background-color: rgba(47, 52, 55, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  color: #ffffff;
  transition: all 0.3s ease;
}

.notion-input:focus {
  outline: none;
  border-color: #ffffff;
  box-shadow: 0 0 0 2px rgba(255, 255, 255, 0.2);
}

.notion-control-button {
  padding: 10px 20px;
  background-color: rgba(55, 53, 47, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  color: #ffffff;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.notion-control-button:hover {
  background-color: rgba(69, 67, 64, 0.8);
  border-color: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
}

.notion-control-button.active {
  background-color: rgba(69, 67, 64, 0.8);
  border-color: #ffffff;
  box-shadow: 0 0 0 2px rgba(255, 255, 255, 0.2);
}

.remove-button {
  background: transparent;
  border: none;
  color: #ff6b6b;
  transition: all 0.3s ease;
}

.remove-button:hover {
  color: #ff4757;
  transform: scale(1.1);
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
  backdrop-filter: blur(5px);
}

.modal-content {
  border-radius: 12px;
  padding: 40px;
  max-width: 480px;
  width: 100%;
}

.current-time {
  position: fixed;
  top: 24px;
  left: 24px;
  font-size: 24px;
  color: #ffffff;
  opacity: 0.8;
  font-weight: 600;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.progress-bar {
  position: absolute;
  top: 0;
  left: 0;
  height: 4px;
  background: linear-gradient(to right, #3498db, #9b59b6);
  transition: width 0.5s linear;
}

.timer-card {
  position: relative;
}

.timer-card::before {
  content: '';
  position: absolute;
  top: -2px;
  left: -2px;
  right: -2px;
  bottom: -2px;
  background: linear-gradient(45deg, #3498db, #9b59b6, #e74c3c, #f1c40f);
  z-index: -1;
  filter: blur(10px);
  opacity: 0;
  transition: opacity 0.3s ease;
}

.timer-card:hover::before {
  opacity: 1;
}
</style>