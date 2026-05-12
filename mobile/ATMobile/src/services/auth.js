import * as SecureStore from 'expo-secure-store';

const TOKEN_KEY = 'sanctum_token';
const USER_KEY  = 'at_user';

export const AuthStorage = {
  saveToken:   (token)  => SecureStore.setItemAsync(TOKEN_KEY, token),
  getToken:    ()       => SecureStore.getItemAsync(TOKEN_KEY),
  removeToken: ()       => SecureStore.deleteItemAsync(TOKEN_KEY),

  saveUser: async (user) => {
    await SecureStore.setItemAsync(USER_KEY, JSON.stringify(user));
  },
  getUser: async () => {
    const raw = await SecureStore.getItemAsync(USER_KEY);
    if (!raw) return null;
    try { return JSON.parse(raw); } catch { return null; }
  },
  removeUser: () => SecureStore.deleteItemAsync(USER_KEY),

  clear: async () => {
    await Promise.all([
      SecureStore.deleteItemAsync(TOKEN_KEY).catch(() => {}),
      SecureStore.deleteItemAsync(USER_KEY).catch(() => {}),
    ]);
  },
};
