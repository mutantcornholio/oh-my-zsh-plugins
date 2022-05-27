# oh-my-zsh-plugins
Custom plugins for "Oh My Zsh"

Install: 
```sh
git clone https://github.com/mutantcornholio/oh-my-zsh-plugins.git 
cd oh-my-zsh-plugins
cp -r plugins/* "$ZSH_CUSTOM/plugins"
```

# Plugins:
## use-dotenv
Loads `.env` file from current dir to your environment. Reverts the changes when you leave directory.  
Updates environment when `.env` file changes.  

(your `.zshrc`)
```sh

ZSH_DOTENV_FILE=.dotenv # confiure name of file to look for; defaults to ".env"
plugins=(... use-dotenv)

RPROMPT='$ZSH_USE_DOTENV_PLUGIN_PROMPT' # show "(.env ✓)" in your right prompt when .env file is applied
```
