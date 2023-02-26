# Settings for the VM
- os : debian-11
## 패키지 설치
`su -` 로 루트 계정에서 진행한다.
- `visudo`
  - `username ALL=(ALL) NOPASSWD:ALL` 추가
  - `NOPASSWD` 로 `sudo` 커맨드 사용 시 패스워드를 입력하지 않아도 된다.
- `apt-get update`
- `apt-get install -y git vim sudo curl fonts-nanum`
  - fonts-nanum : 한글 폰트 설치
## GUI 테마 Windows95 로 만들기
1. debian 설치 시 GUI 환경을 _xfec4_ 로 선택한다.
    - 이미 다른 툴을 설치했다면
    - `sudo apt update && sudo apt upgrade`
    - `sudo apt install tasksel -y`
    - `sudo tasksel install xfce-desktop` 로 설치한다.
2. [Chicago95](https://github.com/grassmunk/Chicago95) 테마 설치
    - `git clone https://github.com/grassmunk/Chicago95` && `cd Chicago95`
    - `python3 installer.py`
3. `reboot`
4. 적용된 모습
    ![img](./pics/debian95.png)
## oh-my-bash 설치
1. `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"`
2. Chicago95 theme 이식
    - `Chicago95/Extras/Chicago95.zsh-theme` 파일을 `~/.oh-my-bash/themes/Chicago95/Chicago95.theme.sh` 로 이동 && 이름 변경
3. `~/.bashrc` 수정
    - `theme="Chicago95"`
