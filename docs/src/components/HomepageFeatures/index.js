import React from 'react';
import clsx from 'clsx';
import styles from './styles.module.css';

const FeatureList = [
  {
    title: 'CMake',
    Svg: require('@site/static/img/CMake.svg').default,
    description: (
      <>
        The build system is based on CMake, a mature build system generator.
        Providing a first class support for C++ compilation.
      </>
    ),
  },
  {
    title: 'Open Source',
    Svg: require('@site/static/img/open_hardware.svg').default,
    description: (
      <>
        SoCMake is fully open source, and provides support for open-source tools as an alternative to commercial tools
      </>
    ),
  },
];

function Feature({Svg, title, description}) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
