# Dockerfile reference

[Dockerfile reference](https://docs.docker.com/engine/reference/builder/)

Docker 는 docker file 에서 instruction 들을 읽어서 자동으로 이미지를 빌드한다. 유저가 이미지를 만들기 위해 호출하는 command 들을  모아놓은 문서 파일이다.

# Format

대소문자는 구분하지 않지만 인자와 구분하기 쉽게 하기 위해 대문자로 instruction 을 적는 것이 컨벤션이다.

순서대로 instruction 들을 실행한다.

**반드시 `FROM` instruction 으로 시작해야 한다.**  `FROM` instruction 은 빌드할 Parent image를 특정한다. `FROM` 앞에는 `FROM` 라인에 사용되는 인수를 선언하는 하나 이상의 `ARG` instruction 만 올 수 있다.

라인 앞에 있는 `#` 만 주석으로 처리한다.

```docker
# Comment
RUN echo 'we are running some # of cool things'
```

주석은 Dockerfile instruction 이 실행되기 전 삭제된다.

```docker
RUN echo hello \
# comment
world
```

즉 이렇게 써도 잘 된다는 뜻이다.

주석 (#) 앞의 공백과 instruction 앞에 있는 공백은 사라지지만  (`RUN` 등) Instruction 의 arugment 안에 있는 공백은 사라지지 않는다.

```docker
RUN echo "\
     hello\
     world"
```

→ 공백 다 포함해서 echo 됨.

# Parser directives

optional. Dockerfile 의 subsequent line 에 영향을 미치는 방법이다. parser directives 는 build 에 layer 를 추가하지 않고 build step 으로 보이지도 않는다.

`# directive=value` 로 사용된다. directive 는 오직 한 번만 사용된다.

`Dockerfile` 맨 위에 있는 것만 유효하다.

대소문자를 구분하지 않지만 소문자가 관례이다. `\` 는 지원하지 않는다.

줄 바꿈이 아닌 공백이 허용되므로 다음 줄은 모두 동일하게 취급된다.

```docker
#directive=value
# directive =value
#	directive= value
# directive = value
#	  dIrEcTiVe=value
```

다음 parser directive 들이 지원된다.

- `syntax`
- `escape`

## syntax

[BuildKit](https://docs.docker.com/build/buildkit/) backend 에서만 가능하고 class builder backend 에서는 무시된다.

[custom dockerfile syntax](https://docs.docker.com/build/buildkit/dockerfile-frontend/) 참고

### escape

```docker
# escape=\ (backslash)
or
# escape=` (backtick)
```

`Dockerfile` 에서 escape character 로 쓰일 문자를 설정한다. 디폴트 : `\`

`RUN` 에서는 세팅 돼있든 없든 escape 되지 않는다.

# Environment replacement

`ENV` 로 생성됨. `Dockerfile` 에 의해 해석되는 변수로써 특정 instruction 에 쓰인다. Escape 들은 variable-like syntax 에서 문자 그대로 포함하기 위해 사용된다.

`$variable_name` 또는 `$(variable_name)` 과 함께 작성한다.  후자는 주로 `${foo}_bar` 같은 경우 사용된다.

`$(variable_name}` 문법은 몇 표준 `bash` modifires 를 지원한다.

- `$(variable:-word}` 는 `variable` 이 설정되어 있으면 그 값을, 설정되어 있지 않으면 `word` 를 결과로 지정한다.
- `${variable:+word}` 는 `variable` 이 설정되어 있으면 `word` 가 결과가 되고 아니면 empty string 이 된다.

모든 경우에서 `word` 는 어떤 문자열이든 될 수 있다. (including additional environment variables.)

Escaping 은 `\` 을 변수 앞에 추가할 수 있게 한다. ex : `\$foo` 를 `$foo`  그대로 해석.

example

```bash
FROM busybox
ENV FOO=/bar
WORKDIR ${FOO}   # WORKDIR /bar
ADD . $FOO       # ADD . /bar
COPY \$FOO /quux # COPY $FOO /quux
```

주석 뒤 글자로 해석됨

환경변수들은 다음 instructions 에서 지원된다.

- `ADD`
- `COPY`
- `ENV`
- `EXPOSE`
- `FROM`
- `LABEL`
- `STOPSIGNAL`
- `USER`
- `VOLUME`
- `WORKDIR`
- `ONBUILD` (when combined with one of the supported instructions above)

한 instruction 에서는 같은 값만 쓸 수 있다.

```docker
ENV abc=hello
ENV abc=bye def=$abc
ENV ghi=$abc
```

둘째 라인의 def 는 hello 이고 셋째 라인의 ghi 는 bye.

# .dockerignore file

docker CLI 는 docker daemon 으로 context 를 보내기 전에 context 의 루트 디렉토리에 있는`.contextfignore` 를 확인한다. 파일이 있다면 패턴에 맞는 파일과 디렉토리를 context 에서 제외한다. 큰 파일이나 민감한 파일을 불필요하게 데몬으로 보내거나 `ADD` 나 `COPY` 로 추가하는 것을 막는다.

CLI 는 `.dockerignore` 파일을 newline 으로 구분된 패턴의 리스트를 Unix shell 의 파일 덩어리들과 유사하게 해석한다.

`#` 로 시작하는 문장은 주석으로 간주한다.

```docker
# comment
*/temp*
*/*/temp*
temp?
```

`temp?`  : temp 뒤에 한 글자가 더 있는 파일을 제외

go 의 [filepath.Match](https://pkg.go.dev/path/filepath#Match) 의 규칙에 따른다. 선행/후행 공백을 제외하고 [filepath.Clean](https://pkg.go.dev/path/filepath#Clean) 을 사용해서 `.`, `..`를 처리한다.

Go의 filepath.Match 를 넘어서 도커는 special wildcard string 인 `**` 를 지원한다. 모든 디렉토리에서 찾는다. `**/*.go` 는 루트 아래의 모든 디렉토리에서 `.go` 로 끝나는 파일을 찾는다.

`!` (exclamation mark) 로 시작하는 라인은 exclusion 에서 exception 을 만든다.

```docker
*.md
!README.md
```

`[README.md](http://README.md)` 를 제외한 모든 `*.md` 파일은 제외된다.

`!` 의 위치는 behavior 에 영향을 미친다.

1. *.txt - ac.txt - !a*.txt

![Screenshot 2023-02-16 at 11.56.21 AM.png](pics/Screenshot_2023-02-16_at_11.56.21_AM.png)

- ac.txt 를 제외하고 싶었으나 뒤에 ! 를 이용한 !a*.txt 가 왔으므로 ac.txt 가 포함됨.
1. *.txt - !a*.txt - ac.txt

![img](pics/Screenshot_2023-02-16_at_11.57.09_AM.png)

- !a*.txt 가 적용된 이후이기 때문에 의도한 대로 ac.txt 는 제외됨.

만약 Dockerfile 이나 .dockerignore 같은 필수파일들을 .dockerignore 에 넣으면 Docker daemon 으로 전송된다. 그러나 `ADD` 나 `COPY` 같은 instruction 에서는 적용되지 않는다.

`*` 를 첫 줄에 적고 `!` 를 이용해서 추가하고 싶은 파일을 추가할 수도 있다.

# FROM

```docker
FROM [--platform=<platform>] <image> [AS <name>]
```

or

```docker
FROM [--platform=<platform>] <image>[:<tag>] [AS <name>]
```

or

```docker
FROM [--platform=<platform>] <image>[@<digest>] [AS <name>]
```

`FROM` instruction 은 새 빌드 스테이지를 초기화하고 다음 instruction 을 위한 Base Image 를 설정한다. 유효한 `Dockerfile` 은 반드시 `FROM` 으로 시작해야 한다.

- `ARG` 는 Dockerfile 에서 `FROM` 이전에 올 수 있는 유일한 instruction 이다.
- `FROM` 은 다중 이미지를 만들거나 한 빌드 스테이지에서 다른 것의 dependency 로 사용하기 위해 한 도커파일에서 여러 번 나올 수 있다. 각각의 새로운 `FROM` 명령어 전에 커밋에 의해 출력된 마지막 이미지 ID를 기록해 두십시오. 각 `FROM` 명령어는 이전 명령어에 의해 생성된 모든 상태를 지웁니다.
- `AS name` 을 `FROM` instruction 에 추가함으로써 이름을 선택적으로 줄 수 있다. 이름은 `FROM` 혹은 `COPY --from=<name>` instruction 으로 참조할 때 사용할 수 있다.
- `tag` 나 `digest` 값도 선택적이다. 생략하면 `latest` 태그가 기본으로 지정된다. builder 는 만약 `tag` 값을 찾지 못하면 에러를 리턴한다.

`--platform` 플래그는 `FROM` 이 여러 플랫폼이미지에서 참조되는 경우 플랫폼을 지정하는 데 사용된다. ex -  `linux/amd64`, `linux/arm64`, or `windows/amd64`. 기본으로 build 요청의 타겟 플랫폼이 사용된다. Global build argument 들은 이 flag 의 값으로 사용된다.  예를 들어 automatic platform ARGs 를 사용하면 native build platform 으로 stage 를 강제 실행하고 이를 사용해서 스테이지 내부의 target platform 으로 크로스 컴파일할 수 있다.

## Understand how ARG and FROM interact

`FROM` instruction 은 첫 `FROM` 이전에 일어난 모든 `ARG` instruction 에 의해 선언된 값을 지원한다.

```docker
ARG  CODE_VERSION=latest
FROM base:${CODE_VERSION}
CMD  /code/run-app

FROM extras:${CODE_VERSION}
CMD  /code/run-extras
```

`FROM` 전에 선언된 `ARG` 는 build stage 외부에 있다. 그래서 `FROM` 이후의 instruction 에서는 사용할 수 없다. 첫 `FROM` 전에 선언된 `ARG` 의 기본값은 빌드 스테이지 내부의 값 없이 `ARG` instruction 을 사용한다.

```docker
ARG VERSION=latest
FROM busybox:$VERSION
ARG VERSION
RUN echo $VERSION > image_version
```

# RUN

RUN 은 두 가지 형태를 가진다.

- `RUN <command>` : shell form. Linux 에서 기본으로 `/bin/sh -c` 로 실행됨
- `RUN ["executable", "param1", "param2"]` : exec form.

`RUN` instruction 은 현재 이미지의 맨 위의 새 레이어에서 커맨드를 실행하고 결과를 commit 한다. 커밋된 이미지의 결과는 Dockerfile 의 다음 단계에서 쓰인다.

`RUN` instruction 을 레이어링 하고 commit 들을 generating 하는 것은 source control 과 마찬가지고 commit 이 저렴하고 컨테이너들이 어떤 이미지 history 에서도 만들어 질 수 있다는 도커의 핵심컨셉을 따른다.

exec form 은 shell string 변경을 방지하고 지정된 shell executable 이 포함되지 않은 베이스 이미지를 사용해서 RUN commands 할 수 있다.

shell form 을 위한 기본 쉘은 `SHELL` 커맨드를 사용해서 변경할 수 있다.

shell form 에서 `\` 를 하나의 RUN instruction 을 계속하기 위해 사용할 수 있다.

```docker
RUN /bin/bash -c 'source $HOME/.bashrc && \
echo $HOME'
```

은 다음과 같다.

```docker
RUN /bin/bash -c 'source $HOME/.bashrc && echo $HOME'
```

다른 쉘을 사용하려면 exec form 을 사용한다.

```docker
RUN ["/bin/bash", "-c", "echo hello"]
```

> exec form 은 JSON array 형식으로 파싱되므로 반드시 double quote(”) 를 사용해야 한다. (single quote 불가능)
>

shell form 과는 다르게, exec form 은 command shell 을 실행하지 않는다. 이것은 일반적인 쉘 프로세싱이 일어나지 않는다는 것을 의미한다. 예를 들어서, `RUN [ "echo, "$HOME"]` 은 `$HOME` 을 치환해주지 않는다. 만약 shell processing 을 원한다면 shell form 을 사용하거나 shell 에서 바로 실행해야 한다. ex : `RUN [ "sh", "-c", "echo $HOME" ]` . exec form 을 사용할 때 쉘을 직접 실행하는 것은 shell form 같이 작동하는 것이므로 docker 가 아니라 shell 이 환경변수 expansion 을 한다.

`RUN` instruction 의 캐시는 다음 빌드동안 자동으로 무효화되지 않는다. 한 instruction 의 캐시 (`RUN apt-get dist-upgrade -y` 같은 것)은 다음 빌드동안 재사용된다. `RUN` instruction 은 `--no-cache` 플래그를 사용해서 캐시를 무효화할 수 있다.

`RUN` 의 캐시는 `ADD` 나 `COPY` 로 무효화 될 수 있다.

## RUN --mount

`RUN --mount` 는 build 가 접근할 수 있는 파일시스템 마운트를 만들 수 있게 해준다.

- host filesystem 이나 다른 build stage 에 bind mount 를 만들 때
- build secret 들이나 ssh-agent socket 들에 접근할 때
- 빌드 속도를 높이기 위해 영구적인 패키지 관리 캐시를 사용할 때

문법 : `--mount=[type=<TYPE>][, option=<value[,koption=<value>]...]`

### Mount types

| Type | Description |
| --- | --- |
| bind (default) | Bind-mount context directories (read-only). |
| cache | Mount a temporary directory to cache directories for compilers and package managers. |
| secret | Allow the build container to access secure files such as private keys without baking them into the image. |
| ssh | Allow the build container to access SSH keys via SSH agents, with support for passphrases. |

### RUN --mount=type=bind

파일 또는 디렉토리를 빌드 컨테이너에 바인딩 할 수 있다. read-only 가 default

| Option | Description |
| --- | --- |
| target | Mount path. |
| source | Source path in the from. Defaults to the root of the from. |
| from | Build stage or image name for the root of the source. Defaults to the build context. |
| rw,readwrite | Allow writes on the mount. Written data will be discarded. |

### RUN --mount=type=cache

빌드 컨테이너가 컴파일러 및 패키지 관리자용 디렉토리를 캐시할 수 있다.

| Option | Description |
| --- | --- |
| id | Optional ID to identify separate/different caches. Defaults to value of target. |
| target | Mount path. |
| ro,readonly | Read-only if set. |
| sharing | One of shared, private, or locked. Defaults to shared. A shared cache mount can be used concurrently by multiple writers. private creates a new mount if there are multiple writers. locked pauses the second writer until the first one releases the mount. |
| from | Build stage to use as a base of the cache mount. Defaults to empty directory. |
| source | Subpath in the from to mount. Defaults to the root of the from. |
| mode | File mode for new cache directory in octal. Default 0755. |
| uid | User ID for new cache directory. Default 0. |
| gid | Group ID for new cache directory. Default 0. |

캐시 디렉토리의 instruction cache 를 무효화하지 않고 빌더 호출 사이에 지속된다. 다른 빌드가 파일을 덮어쓰거나 더 많은 저장 공간이 필요한 경우 GC가 파일을 정리할 수 있으므로 당신의 build 는 캐시 디렉토리의 모든 내용과 함께 작동해야 한다.

### Example: cache Go packages

```docker
# syntax=docker/dockerfile:1
FROM golang
RUN --mount=type=cache,target=/root/.cache/go-build \
  go build ...
```

### Example: cache apt packages

```docker
# syntax=docker/dockerfile:1
FROM ubuntu
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt update && apt-get --no-install-recommends install -y gcc
```

Apt 는 데이터에 대한 독점 엑세스가 필요하므로 캐시는 `sharing-locked` 옵션을 써서 같은 cache mount 를 사용하는 다중 동시 빌드가 다른 것들을 기다리고 같은 캐시 파일에 동시에 접근할 수 없도록 한다. 각 build가 서로 다른 cache directory 를 만들기를 원하면 `sharing-private` 를 사용할 수도 있다.

### RUN --mount=type=tmpfs

This mount type allows mounting tmpfs in the build container.

| Option | Description |
| --- | --- |
| target | Mount path. |
| size | Specify an upper limit on the size of the filesystem. |

### RUN --mount=type=secret

이 마운트 유형을 사용하면 빌드 컨테이너가 개인 키와 같은 보안 파일을 이미지에 굽지 않고 액세스할 수 있다.

| Option | Description |
| --- | --- |
| id | ID of the secret. Defaults to basename of the target path. |
| target | Mount path. Defaults to /run/secrets/ + id. |
| required | If set to true, the instruction errors out when the secret is unavailable. Defaults to false. |
| mode | File mode for secret file in octal. Default 0400. |
| uid | User ID for secret file. Default 0. |
| gid | Group ID for secret file. Default 0. |

### Example: access to S3

```docker
# syntax=docker/dockerfile:1
FROM python:3
RUN pip install awscli
RUN --mount=type=secret,id=aws,target=/root/.aws/credentials \
  aws s3 cp s3://... ...
```

```bash
$ docker buildx build --secret id=aws,src=$HOME/.aws/credentials .
```

### RUN --mount=type=ssh

빌드 컨테이너가 암호를 지원하는 SSH 에이전트로 SSH key 에 액세스 가능.

| Option | Description |
| --- | --- |
| id | ID of SSH agent socket or key. Defaults to “default”. |
| target | SSH agent socket path. Defaults to /run/buildkit/ssh_agent.${N}. |
| required | If set to true, the instruction errors out when the key is unavailable. Defaults to false. |
| mode | File mode for socket in octal. Default 0600. |
| uid | User ID for socket. Default 0. |
| gid | Group ID for socket. Default 0. |

### Example: access to Gitlab

```docker
# syntax=docker/dockerfile:1
FROM alpine
RUN apk add --no-cache openssh-client
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan gitlab.com >> ~/.ssh/known_hosts
RUN --mount=type=ssh \
  ssh -q -T git@gitlab.com 2>&1 | tee /hello
# "Welcome to GitLab, @GITLAB_USERNAME_ASSOCIATED_WITH_SSHKEY" should be printed here
# with the type of build progress is defined as `plain`.
```

```bash
$ eval $(ssh-agent)
$ ssh-add ~/.ssh/id_rsa
(Input your passphrase here)
$ docker buildx build --ssh default=$SSH_AUTH_SOCK .
```

또한 `$SSH_AUTH_SOCK` 대신에 호스트 디렉토이네 있는 `*.pem` 파일의 경로를 정해줄 수 있다. 그러나 passparases 된 (암호화 방식) pem 파일은 지원하지 않는다.

## RUN --network

커맨드가 실행되는 환경의 networking 을 관리한다.

문법 : `--network=<TYPE>`

### Network types

| Type | Description |
| --- | --- |
| default (default) | Run in the default network. |
| none | Run with no network access. |
| host | Run in the host’s network environment. |

### RUN --network=default

플래그를 제공하지 않는 것과 같고 빌드를 위한 기본 네트워크에서 커맨드가 실행된다.

### RUN --network=none

네트워크 접근 없이 커맨드가 실행된다. (`lo` (loopback) 은 여전히 가능하지만 프로세스에 독립되어있다.)

### Example: isolating external effects

```docker
# syntax=docker/dockerfile:1
FROM python:3.6
ADD mypackage.tgz wheels/
RUN --network=none pip install --find-links wheels mypackage
```

`pip` 는 이전 build stage 에서 컨트롤되던 tarfile 에서 제공된 패키지를 설치하는 데만 사용할 수 있다.

### **RUN --network=host**

호스트의 네트워크 환경에서 커맨드가 실행된다. (`docker build --network=host` 와 비슷하지만 instruction 별로 실행된다.)

> Warning
`—-network=host`의 사용은 `[network.host](http://network.host)` 자격에 의해 보호되며 buildkit daemon 을 실행할 때 `--allow-insecure-entitlement network.host`커맨드와 함께 실행하거나 buildkit config 에서  `--allow network.host` 플래그로 빌드 리퀘스트할 필요가 있다.
>

# CMD

`CMD` instruction 은 세 버전이 있다.

- `CMD ["executable", "param1", "param2"]` (exec form, 선호되는 형태)
- `CMD ["param1", "param2"]` (ENTRYPOINT 의 default parameter 로 사용됨)
- `CMD command param1 param2` (shell form)

오직 하나의 `CMD` instruction 만 `Dockerfile` 에 존재할 수 있다. 만약 하나보다 많은 `CMD` 커맨드가 있으면 마지막 `CMD`만 유효하다.

`**CMD` 의 주 목적은 실행하는 컨테이너에 default 를 제공하는 것이다.** 이 default 들은 executable (실행파일) 들을 포함하거나 생략할 수 있다. 생략하는 경우 `ENTRYPOINT` instruction 도 지정해야 한다.

만약 `CMD` 가 `ENTRYPOINT` 의 기본 arguments 를 제공하기 위해 사용되었다면 `CMD` 와 `ENTRYPOINT` instruction 모두 JSON array format 으로 지정되어야 한다.

exec form 은 JSON array 로 파싱되므로 “ 사용

RUN 과 CMD가 동일한 부분 → exec form 에서 일반적인 쉘 프로세싱이 일어나지 않는다.

shell 에서나 exec format 으로 사용될 때 `CMD` instruction 은 이미지를 실행할 때 커맨드 설정한다.

만약 `CMD` 에서 shell form 을 사용했다면 /bin/sh -c 로 실행된다.

```docker
FROM ubuntu
CMD echo "This is a test." | wc -
```

만약 shell 밖에서 <command> 를 실행하고 싶다면 JSON array 로 적고 실행파일의 full path 를 제공해야 한다. 이 array form 은 `CMD` 의 preferred format 이다. 모든 추가 parameter 들은 array 안에서 문자열로 적어야 한다.

```docker
FROM ubuntu
CMD ["/usr/bin/wc","--help"]
```

만약 container 에서 매번 같은 executable 을 실행하길 원한다면 `ENTRYPOINT` 와 `CMD` 를 같이 쓰는 방법을 고려해야 한다.

> `RUN` 과 `CMD` 를 혼동하지 말아야 한다. `RUN` 은 실제로 command 를 실행하고 결과를 commit 한다. `CMD` 는 어떤 것도 build time 에 실행하지 않고 이미지를 위한 의도된 커맨드를 특정한다.
>

# LABEL

```docker
LABEL <key>=<value> <key>=<value> <key>=<value> ...
```

`LABEL` 은 image 에 metadata 를 추가한다. `LABEL` 은 key-value 페어이다. `LABEL` 값에 스페이스를 포함하려면 quote 나 backslash 를 사용해야 한다.

example:

```docker
LABEL "com.example.vendor"="ACME Incorporated"
LABEL com.example.label-with-value="foo"
LABEL version="1.0"
LABEL description="This text illustrates \
that label-values can span multiple lines."
```

이미지는 하나 이상의 라벨을 가질 수 있다. 한 라인에 다중 라벨을 지정할 수 있다. Docker 1.10에 따르면 이것은 최종 이미지의 사이즈를 줄이지만 더 이상은 그렇지 않다. 한 죽에 여러 label 을 적으려면 두 가지 방법 중 하나를 선택하면 된다.

```docker
LABEL multi.label1="value1" multi.label2="value2" other="value3"
```

```docker
LABEL multi.label1="value1" \
      multi.label2="value2" \
      other="value3"
```

base 혹은 parent 이미지(`FROM` 라인에 있는 이미지를 의미함)에 있는 라벨들은 당신의 이미지에 상속된다. 만약 label 이 이미 다른 값으로 존재한다면, 가장 최근에 적용된 값이 이전에 적용된 값을 override 한다.

이미지의 라벨들은 `docker image inspect` 커맨드로 볼 수 있다. `--format` 옵션으로 라벨만 볼 수도 있다.

```bash
docker image inspect --format='' myimage
```

```json
{
  "com.example.vendor": "ACME Incorporated",
  "com.example.label-with-value": "foo",
  "version": "1.0",
  "description": "This text illustrates that label-values can span multiple lines.",
  "multi.label1": "value1",
  "multi.label2": "value2",
  "other": "value3"
}
```

![Screen Shot 2023-02-18 at 1.29.45 PM.png](pics/Screen_Shot_2023-02-18_at_1.29.45_PM.png)

# EXPOSE

```docker
EXPOSE <port> [<port>/<protocol>...]
```

`EXPOSE` instruction 은 도커 에게 컨테이너가 런타임에 특정 네트워크 포트를 listen 한다고 알려준다. 포트가 TCP 혹은 UDP 에서 listen 하는 지 정할 수 있고 특정하지 않으면 기본 프로토콜은 TCP 이다.

`EXPOSE` instuction 은 실제로 포트를 여는 것이 아니다. 이미지를 build 한 사람과 컨테이너를 실행하는 사람 사이의 어떤 port 들이 publish 되기로 의도되었음을 알리는 문서같은 기능을 한다. 실제로 컨테이너를 실행할 때는 `docker run`에서`-p` 를 사용해서 매핑한다. 혹은 `-P` 옵션으로 expose 된 모든 포트를 상위 포트에 매핑한다.

기본으로 `EXPOSE` 는 TCP 를 가정하지만 UDP 도 지정할 수 있다.

```docker
EXPOSE 80/udp
```

TCP 와 UDP 모드 expose 하려면 두 줄이 필요하다.

```docker
EXPOSE 80/tcp
EXPOSE 80/udp
```

이 경우 `docker run -P` 하면 TCP 에 한 번, UDP 에 한 번 포트가 노출된다. 호스트에서는 일시적인 상위 포트를 사용하기 때문에 TCP 와 UDP 에 대한 포트는 같지 않다. (랜덤포트임)

![Screen Shot 2023-02-18 at 1.58.57 PM.png](pics/Screen_Shot_2023-02-18_at_1.58.57_PM.png)

이렇게 호스트의 랜덤한 포트에 하나씩 매핑된다.

`EXPOSE` 세팅에 관계 없이 runtime 에 `-p` 플래그를 사용해서 override 할 수 있다.

```bash
docker run -p 80:80/tcp -p 80:80/udp ...
```

`docker network` 커맨드를 사용하면 포트노출 없이 컨테이너끼리 의사소통 할 수 있다. 네트워크 정보 더보기는 [여기로](https://docs.docker.com/network/).

# ENV

```docker

ENV <key>=<value> ...
```

`ENV` instruction 은 환경변수 `<key>` 에 `<value>` 를 세팅한다. 이 value 는 빌드 스테이지 내의 모든 후속 instruction 에 존재하고 많은 것이 그렇듯 인라인에서 대체될 수 있다. value 는 다른 enviroment value 에 대해서 해석되므로 “가 이스케이프 되지 않으면 제거된다. “ 나 \ 를 사용해서 공백을 포함할 수 있다.

example:

```docker
ENV MY_NAME="John Doe"
ENV MY_DOG=Rex\ The\ Dog
ENV MY_CAT=fluffy
```

한 줄에 여러 변수를 설정할 수 있으므로 다음 예시도 최종 이미지에서 동일한 결과를 생성한다.

```docker
ENV MY_NAME="John Doe" MY_DOG=Rex\ The\ Dog \
    MY_CAT=fluffy
```

`ENV` 를 사용해서 설정한 환경변수는 컨테이너가 실행되는 동안 유지된다. `docker inspect` 로 값을 볼 수 있고 `docker run --env <key>=<value>` 로 값을 변경할 수 있다.

stage는 부모나 조상 stage 에서 설정된 `ENV` 를 상속받는다. 참고 - [멀티 스테이지 빌드](https://docs.docker.com/engine/reference/builder/)

환경변수의 지속성은 예상치못한 부작용을 일으킬 수 있다. 예를 들어 `ENV  DEBIAN_FRONTEND=noninteractive` 는 `apt-get` 의 행동을 바꿔서 사용자들을 혼란스럽게 할 수 있다.

만약 환경변수를 빌드에만 사용하고 싶고 final image 에는 제외하고 싶다면 커맨드로 설정하는 것을 고려할 수 있다.

```docker
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y ...
```

혹은 final image 까지 유지되지는 않는 `ARG` 를 사용한다.

```docker
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y ...
```

### 대체할 수 있는 문법

`ENV` instruction 은 `=` 를 제외하고 `<key> <value>` 로도 가능하다.

```docker
ENV MY_VAR my-value
```

이 문법으로는 하나의 `ENV` instruction 에서 여러 환경변수를 설정할 수 없고 혼란스러울 수 있다.

따라서 이후 버전에서 지워질 수도 있다.

# ADD

두 가지 방법으로 가능.

```docker
ADD [--chown=<user>:<group>] [--checksum=<checksum>] <src>... <dest>
ADD [--chown=<user>:<group>] ["<src>",... "<dest>"]
```

후자는 경로에 화이트스페이스가 있을 때 요구된다.

`--chwon` 기능은 Linux container 를 빌드하는 Dockerfile 에만 지원된다. 유저와 그룹의 소유권 개념은 Linux 와 Windows 간에 호환되지 않으므로 `/etc/passwd` 와 `/etc/group` 을 사용해서 user 와 group 이름을 ID 로 바꾸는 이 기능은 Linux OS 기반 컨테이너에서만 가능하다.

`ADD` instruction 은 새 파일, 디렉토리 혹은 원격 파일 URL 들을 `<src>` 에서 이미지의 파일시스템`<dest>` 에 복사한다.

여러 `<src>` 리소스를 지정할 수 있지만 만약 파일 혹은 디렉토리라면 빌드 컨텍스트의 소스에 상대적인 것으로 해석된다.

각 `<src>` 에는 와일드카드가 포함될 수 있고 Go의 `filepath.Match` 규칙으로 매칭된다.

“hom” 으로 시작하는 모든 파일을 add:

```docker
ADD hom* /mydir/
```

아래의 예시에서, `?` 는 어떤 single character 로도 대체될 수 있다. e.g. “home.txt”

```docker
ADD hom?.txt /mydir/
```

`<dest>` 는 소스가 복사될 컨테이너의 절대경로 혹은 `WORKDIR` 에 의존하는 상대경로이다.

상대경로를 이용해서 `<WORKDIR>/relativeDir/` 에 test.txt 를 추가하는 경우

```docker
ADD test.txt relativeDir/
```

절대경로

```docker
ADD test.txt /absoluteDir/
```

special character 를 포함하는 파일이나 디렉토리를 추가할 때, ( [, ] 같은 문자들) golang 의 규칙에 따라 escape 해야 한다.

`arr[0].txt` 같은 경우

```docker
ADD arr[[]0].txt /mydir/
```

모든 새 파일과 디렉토리는 특정 권한을 요청하기 위해 `--chwon` 플래그로 username 이나 groupname, UID/GID 를 지정해주지 않으면 0번 UID 와 GID 로 만들어진다. `--chown` 플래그 포맷은 username groupname (string) UID GID (Int) 의 모든 조합을 허용한다. groupname 이 없는 username이나 GID 가 없는 UID 는 UID 와 똑같은 숫자를 GID 로 사용한다. 만약 username 이나 groupname 이 제공되면 container 의 루트 파일시스템 `/etc/passwd` 와 `/etc/group` 파일은 정수형태의 UID 혹은 GID 로 변환하기 위해 사용된다. 다음 예시에서 `--chown` 의 유효한 정의를 보여준다.

```docker
ADD --chown=55:mygroup files* /somedir/
ADD --chown=bin files* /somedir/
ADD --chown=1 files* /somedir/
ADD --chown=10:11 files* /somedir/
```

만약 컨테이너 루트 파일시스템이 `/etc/passwd` 이나 `/etc/group` 파일을 갖고 있지 않거나 `--chown` 에서 user , group 이름이 존재하지 않는다면 빌드 시 `ADD` operation 이 실패한다. 숫자형 ID 를 사용하면 조회가 필요없고 컨테이너 루트 파일시스템에 의존하지 않는다.

`<src>` 가 원격 파일 URL 인 경우, destination 은 600 권한을 가진다. 만약 원격 파일이 HTTP `Last-Modified` 헤더를 가진다면 이 헤더의 타임스탬프가 destination 파일의 `mtime` 을 설정하는 데에 사용된다. 그러나 `ADD` 중 처리되는 다른 파일들처럼, `mtime` 은 파일이 변경 되었는지, 캐시를 업데이트해야 하는지의 여부를 결정하는 데에 포함되지 않는다. (신뢰도가 떨어진다는 말 같다)

만약 `Dockerfile` 을 STDIN 을 통해 넘겨서 빌드하면 (`docker build - < somefile`) build context 가 없어서 `Dockerfile` 은 `ADD` instruction 을 기반으로 한 URL 만 가질 수 있다. STDIN 을 통해서 압축된 아카이브를 보낼 수도 있다. (`docker build - < archive.tar.gz`)  이 경우 아카이브의 루트에 있는`Dockerfile` 과 나머지 아카이브가 빌드 컨텍스트로 사용된다.

만약 URL 파일들이 authentication (인증) 으로 보호받는다면 `RUN wget`, `RUN curl` 이나 다른 tool 을 사용해야 한다. (`ADD` 는 미지원)

처음 만나는 `ADD` instruction 은 만약 `<src>` 의 내용이 바뀌었다면 도커파일의 모든 다음 instruction 을 무효화한다. 이는 `RUN` instruction 의 캐시를 무효화하는 것도 포함한다. 더 많은 정보를 얻고 싶다면 [Best practice](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#leverage-build-cache) 로…

`ADD` 는 다음 룰을 따른다.

- `src` 는 반드시 build context 안에 있어야 한다. `ADD ../something /something` 같은 것을 할 수 없다. `docker build` 의 가장 첫 단계가 context directory (와 서브 디렉토리) 를 docker daemon 으로 보내는 것이기 때문이다.
- 만약 `<src>` 가 URL 이고 `<dest>` 가 “/” 로 끝나지 않는다면 다운된 파일이 `<dest>` 로 카피된다.
- `<src>`가 URL 이고 `<dest>` 가 “/” 로 끝나지 않는다면 파일이름을 추측해서 `/dest/filename` 으로 파일을 만든다.
    - ex : `ADD [http://example.com/foobar](http://example.com/foobar) /` 는 `/foobar` 를 만든다.
- `<src>` 가 디렉토리면 디렉토리의 모든 내용이 (메타데이터 포함) 복사된다.
    - 디렉토리 자체가 아니라 안의 내용만 복사된다.
- `<src>` 가 압축된 형식의(인식가능해야함) 로컬 tar 파일일 경우 디렉토리로 unpack 된다. remote URL 의 리소스는 압축해제되지 않는다. `tar -x` 와 같은 behavior 로 copy/unpack 된다.
- `<src>` 가 여러 개의 파일이면 `<dest>` 는 디렉토리여야 하고 /로 끝나야 한다.
- / 가 없으면 일반 파일로 간주되고 src 의 내용이 파일에 기록된다.
- dest 가 없으면 누락된 모든 디렉토리 생성

# COPY

```docker
COPY [--chown=<user>:<group>] <src>... <dest>
COPY [--chown=<user>:<group>] ["<src>",... "<dest>"]
```

`--chown` 은 리눅스 기반에서만 가능함.

`COPY` instruction 은 `<src>` 에서 새 파일이나 디렉토리를 복사하고 컨테이너의 파일시스템 `<dest>` 에 넣는다.

규칙 - ADD 와 거의 같음

`COPY` 는 `--from=<name>` 플래그를 선택적으로 사용해서 유저가 보낸 build context 대신 이전 build stage(`FROM … AS <name>` 으로 만들어짐) 으로 source 의 위치를 설정할 수 있다. name 으로 빌드 context 를 찾을 수 없으면 같은 이름의 이미지를 사용하려고 시도한다.

## ADD vs COPY 다른 점

COPY : 단순히 src → dest 로 대상을 복사한다.

ADD : COPY + additional features. 압축된 아카이브를 추출하거나 원격 URL 에서 파일을 복사할 수 있다.

```docker
ADD https://example.com/archive.tar.gz /tmp/
```

이 경우 앞 경로에서 다운된 파일이 /tmp/ 로 추출된다.

ADD 가 COPY 보다 기능이 많으므로 더 느리다. 단순 복사만 하는 경우 COPY 를 사용하는 것이 좋다.

# ENTRYPOINT

exec form:

```docker
ENTRYPOINT ["executable", "param1", "param2"]

```

shell form :

```docker
ENTRYPOINT command param1 param2
```

`ENTRYPOINT` 는 컨테이너가 실행할 실행파일을 지정해준다.

다음은 nginx 를 기본 content 로 실행한다.

```docker
docker run -i -t --rm -p 80:80 nginx
```

`docker run <image>` 의 모든 인자들은 `ENTRYPOINT` 의 모든 element 뒤에 추가되고 `CMD` 의 모든 element 를 override 한다. `docker run <image> -d` 로 entry point 에 인자를 추가할 수 있다. `docker run --entrypoint` 로 `ENTRYPOINT` 를 override 할 수 있다.

shell form 은 `CMD` 나 커맨드라인 인수가 사용되는 것을 막지만 `/bin/sh-c` 의 서브커맨드로 시작된다는 단점이 있다. 즉 실행파일이 PID 1이 아니고 Unix signal 을 받지 않으므로 `docker stop <container>` 로 SIGTERM을 받을 수 없다.

마지막 `ENTRYPOINT` instruction 만 효과가 있다.

## Exec from ENTRYPOINT example

exec form 으로 안정적인 command 와 argument 를 정하고 `CMD` 로 변경 가능성이 높은 추가 기본값들을 사용할 수 있다.

```docker
FROM ubuntu
ENTRYPOINT ["top", "-b"]
CMD ["-c"]
```

컨테이너 실행 시 `top` 하면 하나의 프로세스만 볼 수 있다.

```bash
docker run -it --rm --name test  top -H

top - 08:25:00 up  7:27,  0 users,  load average: 0.00, 0.01, 0.05
Threads:   1 total,   1 running,   0 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.1 us,  0.1 sy,  0.0 ni, 99.7 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem:   2056668 total,  1616832 used,   439836 free,    99352 buffers
KiB Swap:  1441840 total,        0 used,  1441840 free.  1324440 cached Mem

  PID USER      PR  NI    VIRT    RES    SHR S %CPU %MEM     TIME+ COMMAND
    1 root      20   0   19744   2336   2080 R  0.0  0.1   0:00.04 top
```

`docker exec` 으로 더 자세히 볼 수 있다.

```bash
docker exec -it test ps aux

USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  2.6  0.1  19752  2352 ?        Ss+  08:24   0:00 top -b -H
root         7  0.0  0.1  15572  2164 ?        R+   08:25   0:00 ps aux
```

그리고 `docker stop test` 를 사용해서 `top`을 중단하도록 gracefully 요청할 수 있다.

다음 Dockerfile 은 `ENTRYPOINT`를 사용해서 Apache 를 포어그라운드에서(PID 1로)실행한다.

```docker
FROM debian:stable
RUN apt-get update && apt-get install -y --force-yes apache2
EXPOSE 80 443
VOLUME ["/var/www", "/var/log/apache2", "/etc/apache2"]
ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
```

시작 스크립트를 작성하면 최종 실행파일이 `exec` 이나 `gosu` 로 유닉스 시그널을 받게 할 수 있다.

```bash
#!/usr/bin/env bash
set -e

if [ "$1" = 'postgres' ]; then
    chown -R postgres "$PGDATA"

    if [ -z "$(ls -A "$PGDATA")" ]; then
        gosu postgres initdb
    fi

    exec gosu postgres "$@"
fi

exec "$@"
```

마지막으로, shutdown 시 추가적인 cleanup이 필요할 경우 혹은 둘 이상의 실행파일을 조정해야 하는 경우 `ENTRYPOINT` script 가 유닉스 시그널을 받고, 넘기고, 잘 작동하는지 확인해야 할 필요가 있다.

```bash
#!/bin/sh
# Note: I've written this using sh so it works in the busybox container too

# USE the trap if you need to also do manual cleanup after the service is stopped,
#     or need to start multiple services in the one container
trap "echo TRAPed signal" HUP INT QUIT TERM

# start service in background here
/usr/sbin/apachectl start

echo "[hit enter key to exit] or run 'docker stop <container>'"
read

# stop service and clean up here
echo "stopping apache"
/usr/sbin/apachectl stop

echo "exited $0"
```

이 이미지를 `docker run -it --rm -p 80:80 --name test apache` 으로 실행한다면 컨테이너의 프로세스를 `docker exec` 혹은 `docker top` 으로 검사할 수 있고 스크립트에 아파치를 중지하도록 요청할 수 있다.

```bash
> docker exec -it test ps aux

USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.1  0.0   4448   692 ?        Ss+  00:42   0:00 /bin/sh /run.sh 123 cmd cmd2
root        19  0.0  0.2  71304  4440 ?        Ss   00:42   0:00 /usr/sbin/apache2 -k start
www-data    20  0.2  0.2 360468  6004 ?        Sl   00:42   0:00 /usr/sbin/apache2 -k start
www-data    21  0.2  0.2 360468  6000 ?        Sl   00:42   0:00 /usr/sbin/apache2 -k start
root        81  0.0  0.1  15572  2140 ?        R+   00:44   0:00 ps aux
> docker top test

PID                 USER                COMMAND
10035               root                {run.sh} /bin/sh /run.sh 123 cmd cmd2
10054               root                /usr/sbin/apache2 -k start
10055               33                  /usr/sbin/apache2 -k start
10056               33                  /usr/sbin/apache2 -k start
> /usr/bin/time docker stop test

test
real	0m 0.27s
user	0m 0.03s
sys	0m 0.03s
```

## Shell form ENTRYPOINT example

`ENTRYPOINT` 에 일반 문자열을 넣으면 `/bin/sh -c` 로 실행된다. 이 form 은 쉘 프로세싱을 사용해서 쉘 환경변수를 대체하고  모든`CMD` 나 `docker run` 커맨드 인자를 무시한다. `docker stop` 이 가능하게 하려면 `exec` 으로 시작해야 한다.

```docker
FROM ubuntu
ENTRYPOINT exec top -b
```

이 이미지를 사용했을 때 `PID 1 process`

```bash
> docker run -it --rm --name test top

Mem: 1704520K used, 352148K free, 0K shrd, 0K buff, 140368121167873K cached
CPU:   5% usr   0% sys   0% nic  94% idle   0% io   0% irq   0% sirq
Load average: 0.08 0.03 0.05 2/98 6
  PID  PPID USER     STAT   VSZ %VSZ %CPU COMMAND
    1     0 root     R     3164   0%   0% top -b
```

`docker stop` 으로 깔끔하게 exit 된다.

```bash
> /usr/bin/time docker stop test

test
real	0m 0.20s
user	0m 0.02s
sys	0m 0.04s
```

- 실제 실행해봄

    ```docker
    FROM alpine:latest
    ENTRYPOINT exec top -b
    ```

    ![Screenshot 2023-02-18 at 7.06.41 PM.png](pics
  /Screenshot_2023-02-18_at_7.06.41_PM.png)

    잘 없어짐

    그리고 time 은 bash가 더 아름답다..


만약 `exec` 하지 않았을 경우 PID 1 은 top 이 아니고 sh 이 된다.

```docker
FROM ubuntu
ENTRYPOINT top -b
CMD -- --ignored-param1
```

```bash
> docker run -it --name test top --ignored-param2

top - 13:58:24 up 17 min,  0 users,  load average: 0.00, 0.00, 0.00
Tasks:   2 total,   1 running,   1 sleeping,   0 stopped,   0 zombie
%Cpu(s): 16.7 us, 33.3 sy,  0.0 ni, 50.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :   1990.8 total,   1354.6 free,    231.4 used,    404.7 buff/cache
MiB Swap:   1024.0 total,   1024.0 free,      0.0 used.   1639.8 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
    1 root      20   0    2612    604    536 S   0.0   0.0   0:00.02 sh
    6 root      20   0    5956   3188   2768 R   0.0   0.2   0:00.00 top
```

아름답게 종료되지 않는다면.. `stop` 커맨드는 timeout 이후에 `SIGKILL` 로 종료한다.

```bash
> docker exec -it test ps waux

USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.4  0.0   2612   604 pts/0    Ss+  13:58   0:00 /bin/sh -c top -b --ignored-param2
root         6  0.0  0.1   5956  3188 pts/0    S+   13:58   0:00 top -b
root         7  0.0  0.1   5884  2816 pts/1    Rs+  13:58   0:00 ps waux
/usr/bin/time docker stop test

test
real	0m 10.19s
user	0m 0.04s
sys	0m 0.03s
```

## Understand how CMD and ENTRYPOINT interact

`CMD` 와 `ENTRYPOINT` instruction 은 둘 다 컨테이너 실행 시 실행될 커맨드를 정의한다. 둘을 같이 쓰려면 몇 가지 규칙이 있다.

1. Dockerfile 은 적어도 하나 이상의 `CMD` 나 `ENTRYPOINT` 를 사용해야 한다.
2. `ENTRYPOINT` 는 컨테이너를 실행파일로 사용할 때 정의되어야 한다.
3. `CMD` 는 `ENTRYPOINT` 커맨드의 기본 인자를 지정할 때 사용되거나 컨테이너에서 임시 명령을 실행하는 방법으로 사용해야 한다.
4. `CMD` 는 컨테이너 실행 시 대체 인자로 override 된다.

`ENTRYPOINT`/ `CMD` 를 같이 썼을 때 어떤 커맨드가 실행되는 지 보여주는 표

|  | No ENTRYPOINT | ENTRYPOINT exec_entry p1_entry | ENTRYPOINT [“exec_entry”, “p1_entry”] |
| --- | --- | --- | --- |
| No CMD | error, not allowed | /bin/sh -c exec_entry p1_entry | exec_entry p1_entry |
| CMD [“exec_cmd”, “p1_cmd”] | exec_cmd p1_cmd | /bin/sh -c exec_entry p1_entry | exec_entry p1_entry exec_cmd p1_cmd |
| CMD exec_cmd p1_cmd | /bin/sh -c exec_cmd p1_cmd | /bin/sh -c exec_entry p1_entry | exec_entry p1_entry /bin/sh -c exec_cmd p1_cm |

`CMD` 가 base 이미지에서 정의되었으면 `ENTRYPOINT` 를 설정해서 빈 값으로 `CMD` 를 리셋할 수 있다. 이 시나리오에서  `CMD` 가 값을 가지려면 현재 이미지에서 정의되어야 한다.

# VOLUME

```docker
VOLUME ["/data"]
```

`VOLUME` instruction 은 mount point 를 특정 이름으로 만들고 호스트나 다른 컨테이너에서 외부 마운트된 볼륨을 보유하는 것으로 표시한다. 값은 JSON array (`VOLUME ["/var/log/"`]) 이거나 인자가 여러개인 plain string(`VOLUME /var/log` or `VOLUME /var/log /var/db`) 일 수 있다.

`docker run` 은 베이스 이미지 내에서 새로 만들어진 볼륨을 특정 위치에 있는 데이터로 초기화한다.

다음 dockerfile snippet 을 생각해보자.

```docker
FROM ubuntu
RUN mkdir /myvol
RUN echo "hello world" > /myvol/greeting
VOLUME /myvol
```

이 도커파일은 `docker run` 으로 `/myvol` 이라는 새 마운트 포인트를 만들고 `gretting` 파일을 새 볼륨에 복사하는 이미지를 만든다.

## Notes about specifying volume

- Dockerfile 내에서 볼륨 변경 : 볼륨 선언 후 빌드 단계에서 볼륨 내의 데이터를 변경하면 변경 사항이 삭제된다.
- JSON formatting
- 호스트 디렉토리는 컨테이너 런타임에 정의됨 : 호스트 디렉토리 (마운트포인트) 는 자연적으로 호스트 의존적이다. 이것은 주어진 호스트 디렉토리를 모든 호스트에서 사용가능하다고 보장할 수 없기 때문에 이미지 이식성을 위한 것이다. `VOLUME` instruction 은 `host-dir` 파라미터를 지원하지 않고 컨테이너를 실행하거나 만들 때 mountpoint 를 지정해야 한다.

# USER

```docker
USER <user>[:<group>]
```

or

```docker
USER <UID>[:<GID>]
```

`USER` instruciton 은 user name 이나 user group (or UID, GID) 을 지정할 수 있다. 지정한 user 나 group 현재 스테이지의 나머지에서 기본으로 사용된다. 특정된 유저는 런타임에 `RUN` instruction 을 위해 사용되고 관련 `ENTRYPOINT` 나 `CMD` 를 실행한다.

사용자에게 기본 그룹이 없으면 `root` 그룹으로 실행된다.

# WORKDIR

```docker
WORKDIR /path/to/workdir
```

`WORKDIR` instruction 은 모든 `RUN`, `CMD`, `ENTRYPOINT`, `COPY`, `ADD` 에 대한 워킹 디렉토리를 정한다. `WORKDIR` 이 존재하지 않으면 만들어진다.

`WORKDIR` instruction 은 여러 번 사용될 수 잇다. 만약 상대경로가 주어지면 이전 `WORKDIR` instruction 에 의존적이다.

```docker
WORKDIR /a
WORKDIR b
WORKDIR c
RUN pwd
```

`pwd` 는 `/a/b/c` 이다.

`WORKDIR` instruction 은 `ENV` 로 설정된 환경변수를 리졸브 할 수 있다. Dockerfile 에 명시적으로 세팅된 환경변수만 사용할 수 있다.

```docker
ENV DIRPATH=/path
WORKDIR $DIRPATH/$DIRNAME
RUN pwd
```

`pwd` 는 `/path/$DIRNAME` 이다.

지정하지 않으면 기본 워킹 디렉토리는 `/` 이다. `FROM scratch` (도커에서 제공하는 초경량 이미지) 로 처음부터 빌드하지 않는다면 `WORKDIR` 은 사용하는 이미지의 base 이다.

따라서 의도치않은 operation 을 피하기 위해 `WORKDIR` 은 명시하는 게 좋다.

# ARG

```docker
ARG <name>[=<default value>]
```

`ARG` instruction 은 사용자가 빌드타임에 `docker build` 에  `--build-arg <varname>=<value>` 플래그를 사용해서 넘길 수 있는 변수들을 정의한다. 만약 유저가 build argument 를 정하지 않으면 빌드결과에 경고문을 띄운다.

```docker
[Warning] One or more build-args [foo] were not consumed.
```

도커파일은 여러 개의 `ARG` instruction 을 가질 수 잇다. 예를 들어 다음도 가능하다.

```docker
FROM busybox
ARG user1
ARG buildno
# ...
```

시크릿 (GitHub key 같은 것)을 build-time variable 로 사용하는 것은 추천되지 않는다. docker history command 로 어떤 유저에게나 노출될 수 있다.`[RUN --mount=type=secret](https://www.notion.so/Dockerfile-reference-e33170f1c15e4c36a80ba5795ac1fce2)` 섹션에서 안전하게 사용하는 법 참고.

## Default values

`ARG` instruction 은 선택적으로 기본 값을 가질 수 있다.

```docker
FROM busybox
ARG user1=someuser
ARG buildno=1
# ...
```

기본 값을 가지고 있고 빌더가 아무 값도 넣지 않으면 기본값으로 빌드된다.

## Scope

`ARG` 값 정의는 커맨드라인이 아니라 Dockerfile 에 정의된 줄에 적용된다. (??)

```docker
FROM busybox
USER ${username:-some_user}
ARG username
USER $username
# ...
```

다음으로 빌드

```docker
docker build --build-arg username=what_user .
```

line 2의 `USER` 는 username 이 정의되기 전이므로 `some_user` 가 된다. 4행의 `USER` 는 username 이 정의되고 명령행에서 what_user 이기 때문에 what_user 이다. `ARG` 전에 사용하면 빈 문자열이 생성되낟.

`ARG` instruction 은 정의된 빌드 스테이지의 끝에서 범위를 벗어난다. 여러 단계에서 인수를 사용하려면 `ARG` instruction 을 각 stage 에서 포함해야 한다.

```docker
FROM busybox
ARG SETTINGS
RUN ./run/setup $SETTINGS

FROM busybox
ARG SETTINGS
RUN ./run/other $SETTINGS
```

## Using ARG variables

`ARG` 나 `ENV` instruction 으로 `RUN` instruction 에 사용가능한 변수를 정의할 수 있다. `ENV` instruction 을 이용해서 정의된 환경변수는 항상 같은 이름의 `ARG` 환경 변수를 override 한다.

```docker
FROM ubuntu
ARG CONT_IMG_VER
ENV CONT_IMG_VER=v1.0.0
RUN echo $CONT_IMG_VER
```

해당 도커파일을 다음 커맨드로 빌드한다.

```docker
docker build --build-arg CONT_IMG_VER=v2.0.1 .
```

이 경우 `RUN` instruction 은 유저가 넘긴 `ARG` 값 대신 `v.1.0.0` 을 사용한다. 이는 쉘 스크립트에 정의된 지역스코프 변수가 환경에서 상속받거나 인자로 넘어간 변수를 override 하는 것과 유사하다.

이 예시를 사용해서 `ENV`를 다르게 특정하고 `ARG` 와 `ENV` 사이에 더 유용한 상호작용을 할 수 있다.

```docker
FROM ubuntu
ARG CONT_IMG_VER
ENV CONT_IMG_VER=${CONT_IMG_VER:-v1.0.0}
RUN echo $CONT_IMG_VER
```

`ARG` instruction 과 달리 `ENV` 값은 항상 빌드된 image 에서 유지된다. `--build-arg` 플래그 없는 docker build 를 생각해보자.

이 도커파일을 사용하면 `CONT_IMG_VER` 는 여전히 이미지에 유지되지만 값은 line 3 에 `ENV` 로 정의된 값인 `v.1.0.0` 일 것이다.

이 예제에서의 변수 확장 기술은 커맨드라인에서 argument 를 받게 하고 `ENV` 를 활용하여 최종 이미지에서 유지하게 한다.

## Predefined ARGs

도커는 이미 정의된 `ARG` 변수들을 갖고 있고 이를 사용해서 해당하는`ARG` instruction 을 생략할 수 있다.

- `HTTP_PROXY`
- `http_proxy`
- `HTTPS_PROXY`
- `https_proxy`
- `FTP_PROXY`
- `ftp_proxy`
- `NO_PROXY`
- `no_proxy`
- `ALL_PROXY`
- `all_proxy`

사용을 위해서는 커맨드 라인에 `--build-arg` 플래그를 주면 된다.

```bash
docker build --build-arg HTTPS_PROXY=https://my-proxy.example.com .
```

기본으로 이 pre-defined 변수들은 `docker history` 의 결과에는 나오지 않는다. 이를 제외함으로써 `HTTP_PROXY` 같은 민감한 정보들을 누출하는 위험을 줄일 수 있다.

예를 들어 다음 도커파일을 `--build-arg HTTP_PROXY=http://user:pass@proxy.lon.example.com` 를 사용하여 빌드해보자.

```docker
FROM ubuntu
RUN echo "Hello World"
```

이 경우 `HTTP_PROXY` 변수 값은 `docker history` 에 나오지 않고 캐싱되지도 않는다. 만약 location 을 바꾸기를 원한다면, 그리고 프록시 서버를  `[http://user:pass@proxy.sfo.example.com/](http://user:pass@proxy.sfo.example.com/)` 로 바꾸기를 원한다면 후속 빌드는 cache miss 를 내지 않는다.

이 행동을 override 하려면 `ARG` 를 다음과 같이 추가하면 된다.

```docker
FROM ubuntu
ARG HTTP_PROXY
RUN echo "Hello World"
```

이러면 도커파일을 빌드할 때 `HTTP_PROXY` 는 `docker history` 에 유지되고 값을 바꾸면 빌드 캐시를 무효화 한다.

# ONBUILD

```docker
ONBUILD <INSTRUCTION>
```

`ONBUILD` instruction 은 나중에 이미지가 다른 build 의 베이스가 될 때 실행될 trigger instruction 을 추가한다. 이 trigger 는 하위 빌드 context 에서 `FROM` 직후에 삽입된 것 처럼 실행된다.

모든 build instruction 을 trigger 로 등록할 수 있다.

다른 이미지의 base 가 될 이미지(ex - 어플리케이션 빌드환경 혹은 유저 설정으로 커스터마이즈 된 daemon)를 빌드할 때 유용하다.

예를 들어서 당신의 이미지가 파이썬 앱 빌더에 재사용된다면 특정 디렉토리에 추가된 어플리케이션 소스코드와 그 이후에 실행될 build script 를 필요로 할 것이다. 어플 소스코드에 현재 접근 할 수 없기 때문에 `ADD` 나 `RUN` 을 당장 호출할 수 없다. 응용프로그램 개발자에게 보일러플레이트를 제공해서 복사 붙여넣기 할 수도 잇지만 이는 어플리케이션 별 코드와 혼합되므로 비효율적이며 업데이트 하기 어렵고 오류가 발생하기 쉽다.

`ONBUILD` 를 사용해서 next build stage 에서 실행될 advance instruction 을 등록하는 것이 해결책이 된다.

적다보니 아직 필요 없을 듯 하여 잠시 그냥 복붙을 해보겄다

Here’s how it works:

1. When it encounters an `ONBUILD` instruction, the builder adds a trigger to the metadata of the image being built. The instruction does not otherwise affect the current build.
2. At the end of the build, a list of all triggers is stored in the image manifest, under the key `OnBuild`. They can be inspected with the `docker inspect` command.
3. Later the image may be used as a base for a new build, using the `FROM` instruction. As part of processing the `FROM` instruction, the downstream builder looks for `ONBUILD` triggers, and executes them in the same order they were registered. If any of the triggers fail, the `FROM` instruction is aborted which in turn causes the build to fail. If all triggers succeed, the `FROM` instruction completes and the build continues as usual.
4. Triggers are cleared from the final image after being executed. In other words they are not inherited by “grand-children” builds.

For example you might add something like this:

`ONBUILD ADD . /app/src
ONBUILD RUN /usr/local/bin/python-build --dir /app/src`

> Warning
>
>
> Chaining `ONBUILD` instructions using `ONBUILD ONBUILD` isn’t allowed.
>

> Warning
>
>
> The `ONBUILD` instruction may not trigger `FROM` or `MAINTAINER` instructions.
>

# STOPSIGNAL

```docker
STOPSIGNAL signal
```

`STOPSIGNAL` instruction 은 exit 하기 위해 컨테이너에 보낼 system call 시그널을 설정한다. 이 시그널은 `SIG<NAME>` 형태 (SIGKILL) 나 unsigned number (9) 형태가 될 수 있다. 지정하지 않으면 `SIGTERM` 이다.

이미지의 기본 stopsignal 은 컨테이터마다 override 될 수 있다. `docker run` 이나 `docker create` 에 `--stop-signal` 사용

# HEALTHCHECK

- `HEALTHCHECK [OPTIONS] CMD command` (check container health by running a command inside the container)
- `HEALTHCHECK NONE` (disable any healthcheck inherited from the base image)

`HEALTHCHECK` instruction 은 도커에게 이 컨테이너가 여전히 작동하는 지 여부를 어떻게 확인하는 지 알려준다. 이것은 무한 루프에 갇혀있거나 새 커넥션을 관리할 수 없는, 여전히 서버프로세스는 실행 중인 케이스들을 감지할 수 있다.

컨테이너가 특정된 healthcheck를 갖고 있을 때, normal status 에 더해서 *health* status 를 가진다. 이 상태는 초기에 `starting` 이다. health check 를 통과하면 `healthy` 가 된다. (이전 상태는 상관없음) 연속으로 특정 숫자만큼 실패하면 `unhealthy` 가 된다.

`CMD` 전에 나타날 수 있는 옵션 :

- `-interval=DURATION` (default: `30s`)
- `-timeout=DURATION` (default: `30s`)
- `-start-period=DURATION` (default: `0s`)
- `-retries=N` (default: `3`)

health check 는 컨테이너가 실행되고 interval 초 뒤에 실행된 후 이전 check 이후로 interval 초 만큼 다시 기다리고 실행한다.

한 check 는 timeout 초보다 오래 걸리면 fail 로 간주된다.

retries 만큼 연속으로 실패하면 `unhealthy` 로 간주된다.

start periood 는 부트스트랩이 필요한 컨테이너의 초기화 시간을 제공한다. 이 동안의 failure 는 retries 에 반영되지 않는. 그러나 health check 가 이 기간동안 성공하면 컨테이너는 시작되었다고 간주되고 모든 연속적인 실패가 retries 로 카운트된다.

`HEALTHCHECK` instruction 은 도커파일 당 하나만 올 수 있다. 만약 여러 개를 정의하면 마지막 것이 유효하다.

`CMD` 키워드 이후의 커맨드는 shell command 이거나 exec array 이다.

커맨드의 exit status 는 컨테이너의 상태를 나타낸다.

- 0 : success - 컨테이너는 healthy 하고 ready for use.
- 1 : unhealthy - 올바르게 작동하지 않고 있음
- 2 : reserved - 이 exit code 는 사용하지 않음

매 5초마다 체크하려면:

```docker
HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost/ || exit 1
```

실패한 prove 를 디버깅하기 위해 출력 문자(UTF-8 , stdout or stderr 에 출력)는 health status 에 저장되고 `docker inspect` 로 질의할 수 있다. 짧게 유지해야 한다.(앞 4096 바이트만 현재 저장됨)

컨테이너의 health status 가 바뀌면, `health_status` 이벤트는 새 이벤트로 생성된다.

# SHELL

```docker
SHELL ["executable", "parameters"]
```

`SHELL` instructon 은 shell form 이나 command 에 사용되는 기본 쉘을 override 한다. 리눅스 기본 쉘은 `["/bin/sh", "-c"]` 이다. `SHELL` instruction 은 반드시 JSON 형태로 작성되어야 한다.

`SHELL` instruction 은 특히 윈도우 ( 다른 native shell 두 개를 사용 - `cmd`, `powrershell`) 에 유용하다.

여러 번 선언할 수 있고 각 `SHELL` instruction 은 이전 것은 override 해서 후속 instruction 에 영향을 미친다.
