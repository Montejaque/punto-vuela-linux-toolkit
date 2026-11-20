function CachedImage({src,alt,className,fallback,hideOnError=false}:{src:string;alt:string;className?:string;fallback?:string;hideOnError?:boolean}){
 const [resolved,setResolved]=useState("");
 const [failed,setFailed]=useState(false);
 useEffect(()=>{let active=true;setResolved("");setFailed(false);const bridge=(window as any).puntoVuela?.invoke;if(typeof bridge!=="function"){if(active){setResolved(src);setFailed(true);}return;}void bridge("images.cache",{url:src}).then((data:string)=>{if(active)setResolved(data);}).catch(()=>{if(active){setResolved(fallback||src);setFailed(true);}});return()=>{active=false;};},[src,fallback]);
 if(failed&&hideOnError)return null;
 if(!resolved)return null;
 return <img className={className} src={resolved} alt={alt} loading="lazy" onError={e=>{if(fallback&&e.currentTarget.src!==fallback)e.currentTarget.src=fallback;else e.currentTarget.style.display="none";}}/>;
}function CachedImage({src,alt,className,fallback,hideOnError=false}:{src:string;alt:string;className?:string;fallback?:string;hideOnError?:boolean}){
 const [resolved,setResolved]=useState(src);
 const [stage,setStage]=useState<"cache"|"remote"|"fallback">("cache");
 useEffect(()=>{let active=true;setResolved(src);setStage("cache");const bridge=(window as any).puntoVuela?.invoke;if(typeof bridge!=="function"){setStage("remote");return;}void bridge("images.cache",{url:src}).then((data:any)=>{if(active&&typeof data==="string"&&data.startsWith("data:image/"))setResolved(data);else if(active)setStage("remote");}).catch(()=>{if(active)setStage("remote");});return()=>{active=false;};},[src]);
 if(stage==="fallback"&&hideOnError)return null;
 return <img className={className} src={resolved} alt={alt} loading="lazy" onError={()=>{if(stage==="cache"){setStage("remote");setResolved(src);return;}if(stage==="remote"&&fallback&&fallback!==src){setResolved(fallback);setStage("fallback");return;}if(hideOnError)setStage("fallback");}}/>;
}